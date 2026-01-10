#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# parallel_executor.sh - Parallel Job Execution for Batch Mode
# Part of adamantium v1.2
# ═══════════════════════════════════════════════════════════════

# Este módulo proporciona ejecución paralela con 3 niveles de fallback:
# Tier 1: GNU parallel (mejor performance)
# Tier 2: xargs (buen performance, disponible generalmente)
# Tier 3: Pure bash (fallback garantizado)

# Variables globales
EXECUTOR_HAS_PARALLEL=false
EXECUTOR_HAS_XARGS=false
EXECUTOR_TIER=3

# ═══════════════════════════════════════════════════════════════
# DETECCIÓN DE CAPACIDADES
# ═══════════════════════════════════════════════════════════════

executor_check_capabilities() {
    # Verificar GNU parallel
    if command -v parallel &>/dev/null; then
        # Verificar que sea GNU parallel (no moreutils parallel)
        if parallel --version 2>&1 | grep -q "GNU parallel"; then
            EXECUTOR_HAS_PARALLEL=true
            EXECUTOR_TIER=1
        fi
    fi

    # Verificar xargs
    if command -v xargs &>/dev/null; then
        EXECUTOR_HAS_XARGS=true
        [ "$EXECUTOR_TIER" -eq 3 ] && EXECUTOR_TIER=2
    fi

    # Reportar tier si verbose
    if [ "${BATCH_VERBOSE:-false}" = true ]; then
        case $EXECUTOR_TIER in
            1) echo -e "${GREEN}${CHECK} Using GNU parallel (Tier 1)${NC}" ;;
            2) echo -e "${YELLOW}${WARN} Using xargs (Tier 2)${NC}" ;;
            3) echo -e "${CYAN}${INFO} Using pure bash (Tier 3)${NC}" ;;
        esac
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════
# AUTO-TUNING DE JOBS
# ═══════════════════════════════════════════════════════════════

determine_job_count() {
    local file_count="$1"
    local user_jobs="${BATCH_JOBS:-0}"

    # Si el usuario especificó jobs, usar ese valor
    if [ "$user_jobs" -gt 0 ]; then
        echo "$user_jobs"
        return 0
    fi

    # Auto-detectar cores
    local cores=$(nproc 2>/dev/null || echo "2")

    # Estrategia adaptativa basada en tamaño del batch
    local optimal

    if [ "$file_count" -lt 10 ]; then
        # Batch pequeño: 2 jobs
        optimal=2
    elif [ "$file_count" -lt 100 ]; then
        # Batch mediano: cores - 1 (dejar 1 core libre)
        optimal=$((cores > 1 ? cores - 1 : 1))
    else
        # Batch grande: usar todos los cores
        optimal=$cores
    fi

    # Asegurar al menos 1 job
    [ $optimal -lt 1 ] && optimal=1

    echo "$optimal"
}

# ═══════════════════════════════════════════════════════════════
# DISPATCHER PRINCIPAL
# ═══════════════════════════════════════════════════════════════

parallel_execute() {
    local jobs="$1"
    shift
    local -a files=("$@")

    local file_count=${#files[@]}

    # Validar que hay archivos
    [ $file_count -eq 0 ] && return 1

    # Auto-tuning si jobs=0
    if [ "$jobs" -eq 0 ]; then
        jobs=$(determine_job_count "$file_count")
    fi

    # Distribuir jobs (no más jobs que archivos)
    [ $jobs -gt $file_count ] && jobs=$file_count

    # Verbose info
    if [ "${BATCH_VERBOSE:-false}" = true ]; then
        echo -e "${CYAN}${INFO} Processing ${file_count} files with ${jobs} parallel jobs${NC}"
    fi

    # Dispatch según tier disponible
    case $EXECUTOR_TIER in
        1)
            parallel_execute_gnu_parallel "$jobs" "${files[@]}"
            ;;
        2)
            parallel_execute_xargs "$jobs" "${files[@]}"
            ;;
        3)
            parallel_execute_bash "$jobs" "${files[@]}"
            ;;
    esac

    return $?
}

# ═══════════════════════════════════════════════════════════════
# TIER 1: GNU PARALLEL
# ═══════════════════════════════════════════════════════════════

parallel_execute_gnu_parallel() {
    local jobs="$1"
    shift
    local -a files=("$@")

    # Exportar función process_single_file para que parallel pueda usarla
    export -f process_single_file
    export -f progress_update

    # Exportar variables necesarias
    export PROGRESS_STATE_DIR
    export ADAMANTIUM_BIN
    export BATCH_VERBOSE

    # Ejecutar con GNU parallel
    printf '%s\n' "${files[@]}" | parallel \
        --jobs "$jobs" \
        --will-cite \
        --line-buffer \
        process_single_file {}

    return 0
}

# ═══════════════════════════════════════════════════════════════
# TIER 2: XARGS
# ═══════════════════════════════════════════════════════════════

parallel_execute_xargs() {
    local jobs="$1"
    shift
    local -a files=("$@")

    # Exportar variables necesarias
    export PROGRESS_STATE_DIR
    export ADAMANTIUM_BIN
    export BATCH_VERBOSE
    export BATCH_LIGHTWEIGHT

    # Para xargs, usamos una función simplificada que escribe directamente a archivos
    # en lugar de usar progress_update (que depende de variables/funciones no exportables)
    _xargs_process_file() {
        local file="$1"
        local dir=$(dirname "$file")
        local basename=$(basename "$file")
        local extension="${basename##*.}"
        local name="${basename%.*}"
        local output="${dir}/${name}_clean.${extension}"

        local result=0
        if [ "${BATCH_LIGHTWEIGHT:-false}" = true ]; then
            "$ADAMANTIUM_BIN" --lightweight "$file" "$output"
            result=$?
        elif [ "${BATCH_VERBOSE:-false}" = true ]; then
            "$ADAMANTIUM_BIN" "$file" "$output"
            result=$?
        else
            "$ADAMANTIUM_BIN" "$file" "$output" &>/dev/null
            result=$?
        fi

        # Actualizar progreso directamente a archivos (sin funciones complejas)
        if [ "${BATCH_LIGHTWEIGHT:-false}" != true ] && [ -n "$PROGRESS_STATE_DIR" ]; then
            (
                flock -x 200
                local current=$(cat "${PROGRESS_STATE_DIR}/counter.txt" 2>/dev/null || echo "0")
                echo "$((current + 1))" > "${PROGRESS_STATE_DIR}/counter.txt"
                if [ $result -eq 0 ]; then
                    local success=$(cat "${PROGRESS_STATE_DIR}/success.txt" 2>/dev/null || echo "0")
                    echo "$((success + 1))" > "${PROGRESS_STATE_DIR}/success.txt"
                else
                    local errors=$(cat "${PROGRESS_STATE_DIR}/errors.txt" 2>/dev/null || echo "0")
                    echo "$((errors + 1))" > "${PROGRESS_STATE_DIR}/errors.txt"
                    echo "$file" >> "${PROGRESS_STATE_DIR}/error_files.txt"
                fi
            ) 200>"${PROGRESS_STATE_DIR}/lock"
        fi

        return $result
    }
    export -f _xargs_process_file

    # xargs con -P para paralelización
    # Nota: -I {} implica -n 1, no usar ambos (son mutuamente excluyentes)
    printf '%s\n' "${files[@]}" | xargs \
        -P "$jobs" \
        -I {} \
        bash -c '_xargs_process_file "$@"' _ {}

    return 0
}

# ═══════════════════════════════════════════════════════════════
# TIER 3: PURE BASH
# ═══════════════════════════════════════════════════════════════

parallel_execute_bash() {
    local jobs="$1"
    shift
    local -a files=("$@")

    local running=0
    local -a pids=()

    for file in "${files[@]}"; do
        # Esperar si alcanzamos el límite de jobs
        while [ $running -ge $jobs ]; do
            # Esperar a que termine cualquier job (bash 4.3+)
            if command -v wait &>/dev/null && wait -n 2>/dev/null; then
                running=$((running - 1))
            else
                # Fallback para bash antiguo: esperar al primero de la lista
                wait "${pids[0]}" 2>/dev/null
                running=$((running - 1))
                pids=("${pids[@]:1}")  # Remover primer elemento
            fi
        done

        # Ejecutar proceso en background
        process_single_file "$file" &
        local pid=$!
        pids+=("$pid")
        running=$((running + 1))
    done

    # Esperar a que terminen todos los jobs restantes
    wait

    return 0
}

# ═══════════════════════════════════════════════════════════════
# UTILIDADES Y OPTIMIZACIONES (v2.3)
# ═══════════════════════════════════════════════════════════════

get_optimal_batch_size() {
    local total_files="$1"
    local jobs="$2"

    # Calcular tamaño óptimo de batch
    # Objetivo: mantener todos los workers ocupados con mínimo overhead

    local batch_size=$((total_files / jobs))

    # Ajuste adaptativo basado en número total de archivos
    if [ $total_files -lt 20 ]; then
        # Pocos archivos: batch de 1 para máxima granularidad
        batch_size=1
    elif [ $total_files -lt 100 ]; then
        # Batch mediano: 2-5 archivos por batch
        batch_size=$((batch_size > 5 ? 5 : (batch_size < 2 ? 2 : batch_size)))
    else
        # Batch grande: 5-20 archivos por batch
        batch_size=$((batch_size > 20 ? 20 : (batch_size < 5 ? 5 : batch_size)))
    fi

    echo "$batch_size"
}

# Procesar múltiples archivos en un solo subshell (reduce overhead)
process_batch_files() {
    local -a files=("$@")

    for file in "${files[@]}"; do
        process_single_file "$file"
    done
}

# Exportar para uso en paralelo
export -f process_batch_files

validate_job_count() {
    local jobs="$1"

    # Validar que sea un número
    if ! [[ "$jobs" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}${CROSS} Invalid job count: $jobs (must be a number)${NC}" >&2
        return 1
    fi

    # Advertir si es muy alto
    if [ "$jobs" -gt 64 ]; then
        echo -e "${YELLOW}${WARN} Job count very high ($jobs). This may cause system instability.${NC}" >&2
        read -p "Continue? [y/N] " response
        [[ ! "$response" =~ ^[yY]$ ]] && return 1
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════
# ESTRATEGIAS DE DISTRIBUCIÓN
# ═══════════════════════════════════════════════════════════════

# Round-robin: distribuir archivos equitativamente entre workers
distribute_round_robin() {
    local jobs="$1"
    shift
    local -a files=("$@")

    for ((i=0; i<jobs; i++)); do
        local -a worker_files=()
        for ((j=i; j<${#files[@]}; j+=jobs)); do
            worker_files+=("${files[$j]}")
        done

        # Procesar batch en background
        if [ ${#worker_files[@]} -gt 0 ]; then
            (
                for file in "${worker_files[@]}"; do
                    process_single_file "$file"
                done
            ) &
        fi
    done

    wait
    return 0
}
