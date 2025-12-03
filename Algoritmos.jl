using Statistics
import Pkg;
Pkg.add("PyPlot")

include("Processos.jl")
include("Gera_Grafico.jl")



function fcfs(processos; custo_troca=1, n_cores=2)
    tempos_cores = zeros(Int, n_cores)
    procs = sort(processos, by=p -> p.chegada)

    resultados = []
    ultimo_id_cores = Vector{Union{Nothing,Int}}(nothing, n_cores)

    for p in procs

        indice_core = argmin(tempos_cores)
        tempo_disponivel = tempos_cores[indice_core]

        inicio = max(tempo_disponivel, p.chegada)


        if ultimo_id_cores[indice_core] !== nothing && ultimo_id_cores[indice_core] != p.id
            if inicio >= tempo_disponivel
                inicio += custo_troca
            end
        end
        ultimo_id_cores[indice_core] = p.id

        fim = inicio + p.duracao

        tempos_cores[indice_core] = fim

        push!(resultados, (id=p.id, core=indice_core, chegada=p.chegada, inicio=inicio, fim=fim))
    end

    return resultados
end

function sjf(processos; custo_troca=1, n_cores=2)
    pendentes = collect(processos)
    execucao = []
    tempos_cores = zeros(Int, n_cores)
    ultimo_id_cores = Vector{Union{Nothing,Int}}(nothing, n_cores)

    while !isempty(pendentes)
        indice_core = argmin(tempos_cores)
        tempo_atual_core = tempos_cores[indice_core]

        disponiveis = filter(p -> p.chegada <= tempo_atual_core, pendentes)

        if isempty(disponiveis)
            proxima_chegada = minimum([p.chegada for p in pendentes])
            tempos_cores[indice_core] = proxima_chegada
            continue
        end

        idx_min = argmin([d.duracao for d in disponiveis])
        escolhido = disponiveis[idx_min]


        if ultimo_id_cores[indice_core] !== nothing && ultimo_id_cores[indice_core] != escolhido.id
            tempo_atual_core += custo_troca
        end
        ultimo_id_cores[indice_core] = escolhido.id

        inicio = tempo_atual_core
        fim = inicio + escolhido.duracao
        tempos_cores[indice_core] = fim
        push!(execucao, (id=escolhido.id, core=indice_core, chegada=escolhido.chegada, inicio=inicio, fim=fim))

        deleteat!(pendentes, findfirst(x -> x.id == escolhido.id, pendentes))
    end

    return execucao
end


function prioridade(processos; custo_troca=1, n_cores=2)
    pendentes = copy(processos)
    execucao = []
    tempos_cores = zeros(Int, n_cores)
    ultimo_id_cores = Vector{Union{Nothing,Int}}(nothing, n_cores)

    while !isempty(pendentes)
        indice_core = argmin(tempos_cores)
        tempo_atual_core = tempos_cores[indice_core]
        disponiveis = filter(p -> p.chegada <= tempo_atual_core, pendentes)

        if isempty(disponiveis)
            proxima_chegada = minimum([p.chegada for p in pendentes])
            tempos_cores[indice_core] = proxima_chegada
            continue
        end

        idx_min = argmin([p.prioridade for p in disponiveis])
        escolhido = disponiveis[idx_min]

        if ultimo_id_cores[indice_core] !== nothing && ultimo_id_cores[indice_core] != escolhido.id
            tempo_atual_core += custo_troca
        end
        ultimo_id_cores[indice_core] = escolhido.id



        inicio = tempo_atual_core
        fim = inicio + escolhido.duracao
        tempos_cores[indice_core] = fim

        push!(execucao, (id=escolhido.id, core=indice_core, chegada=escolhido.chegada, inicio=inicio, fim=fim))

        deleteat!(pendentes, findfirst(x -> x.id == escolhido.id, pendentes))
    end

    return execucao
end

function round_robin(processos, quantum; custo_troca=1, n_cores=2)
    processos = sort(processos, by=p -> p.chegada)

    fila = []
    idx_chegada = 1
    restante = Dict(p.id => p.duracao for p in processos)

    tempos_cores = zeros(Int, n_cores)
    ultimo_id_cores = Vector{Union{Nothing,Int}}(nothing, n_cores)

    execucao = []

    while idx_chegada ≤ length(processos) || !isempty(fila)

        indice_core = argmin(tempos_cores)
        tempo_atual_core = tempos_cores[indice_core]

        while idx_chegada ≤ length(processos) && processos[idx_chegada].chegada ≤ tempo_atual_core
            push!(fila, processos[idx_chegada])
            idx_chegada += 1
        end

        if isempty(fila)
            if idx_chegada ≤ length(processos)
                tempos_cores[indice_core] = processos[idx_chegada].chegada
            else
                break
            end
            continue
        end

        p = popfirst!(fila)

        if ultimo_id_cores[indice_core] !== nothing && ultimo_id_cores[indice_core] != p.id
            tempo_atual_core += custo_troca
        end
        ultimo_id_cores[indice_core] = p.id

        exec_time = min(quantum, restante[p.id])
        inicio = max(tempo_atual_core, p.chegada)
        fim = inicio + exec_time
        push!(execucao, (id=p.id, core=indice_core, chegada=p.chegada, inicio=inicio, fim=fim))

        restante[p.id] -= exec_time
        tempos_cores[indice_core] = fim

        while idx_chegada ≤ length(processos) && processos[idx_chegada].chegada ≤ fim
            push!(fila, processos[idx_chegada])
            idx_chegada += 1
        end

        if restante[p.id] > 0
            push!(fila, p)
        end
    end

    return execucao
end





function calcular_metricas(resultado, instancia)
    inicio_processos = Dict{Int,Int}()
    fim_processos = Dict{Int,Int}()

    for fatia in resultado
        id = fatia.id

        if !haskey(inicio_processos, id)
            inicio_processos[id] = fatia.inicio
        end

        fim_processos[id] = fatia.fim
    end

    turnarounds = 0.0
    respostas = 0.0
    esperas = 0.0

    n = length(instancia)
    processos_concluidos = 0

    for p in instancia
        id = p.id

        if haskey(fim_processos, id)
            chegada = p.chegada
            duracao = p.duracao

            turnaround = fim_processos[id] - chegada
            resposta = inicio_processos[id] - chegada
            espera = turnaround - duracao

            turnarounds += turnaround
            respostas += resposta
            esperas += espera
            processos_concluidos += 1
        end
    end

    if processos_concluidos == 0
        return (turnaround=0.0, resposta=0.0, espera=0.0, vazao=0.0)
    end

    tempo_total = maximum(values(fim_processos))

    vazao = processos_concluidos / tempo_total

    return (
        turnaround=round(turnarounds / processos_concluidos, digits=2),
        resposta=round(respostas / processos_concluidos, digits=2),
        espera=round(esperas / processos_concluidos, digits=2),
        vazao=round(vazao, digits=4),
        makespan=tempo_total 
    )
end


function EscolheProcesso()
    println("
    Escolha entre um dos conjuntos de processos:
    1 - Normais
    2 - Duração Maior
    3 - Mais Empates
    4 - Inicio pesado (Pior pro FCFS)
    5 - Processos mais variados
    ")
    escolha1 = parse(Int, readline())

    println("
    Escolha um valor para o quantum:
    ")
    escolha2 = parse(Int, readline())

    println("
    Escolha a quantidade de cores:
    ")
    cores = parse(Int, readline())

    if (escolha1 == 1)
        m_rr = calcular_metricas(round_robin(P1, escolha2, n_cores=cores), P1)
        m_fcfs = calcular_metricas(fcfs(P1, n_cores=cores), P1)
        m_sjf = calcular_metricas(sjf(P1, n_cores=cores), P1)
        m_prioridade = calcular_metricas(prioridade(P1, n_cores=cores), P1)
    end

    if (escolha1 == 2)
        m_rr = calcular_metricas(round_robin(P2, escolha2, n_cores=cores), P2)
        m_fcfs = calcular_metricas(fcfs(P2, n_cores=cores), P2)
        m_sjf = calcular_metricas(sjf(P2, n_cores=cores), P2)
        m_prioridade = calcular_metricas(prioridade(P2, n_cores=cores), P2)
    end

    if (escolha1 == 3)
        m_rr = calcular_metricas(round_robin(P3, escolha2, n_cores=cores), P3)
        m_fcfs = calcular_metricas(fcfs(P3, n_cores=cores), P3)
        m_sjf = calcular_metricas(sjf(P3, n_cores=cores), P3)
        m_prioridade = calcular_metricas(prioridade(P3, n_cores=cores), P3)
    end

    if (escolha1 == 4)
        m_rr = calcular_metricas(round_robin(P4, escolha2, n_cores=cores), P4)
        m_fcfs = calcular_metricas(fcfs(P4, n_cores=cores), P4)
        m_sjf = calcular_metricas(sjf(P4, n_cores=cores), P4)
        m_prioridade = calcular_metricas(prioridade(P4, n_cores=cores), P4)
    end

    if (escolha1 == 5)
        m_rr = calcular_metricas(round_robin(P5, escolha2, n_cores=cores), P5)
        m_fcfs = calcular_metricas(fcfs(P5, n_cores=cores), P5)
        m_sjf = calcular_metricas(sjf(P5, n_cores=cores), P5)
        m_prioridade = calcular_metricas(prioridade(P5, n_cores=cores), P5)
    end

    println("Resultados RR: ", m_rr)
    println("Resultados FCFS: ", m_fcfs)
    println("Resultados SJF: ", m_sjf)
    println("Resultados PRIORIDADE: ", m_prioridade)

    Grafico(m_fcfs, m_sjf, m_rr, m_prioridade)

end



EscolheProcesso()
