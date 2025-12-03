using Plots
pyplot()
gr()

function Grafico(m_fcfs, m_sjf, m_rr, m_prioridade)
    
    algoritmos = ["RR", "FCFS", "SJF", "Prioridade"]

    turnaround = [m_rr.turnaround, m_fcfs.turnaround, m_sjf.turnaround, m_prioridade.turnaround]
    resposta   = [m_rr.resposta,   m_fcfs.resposta,   m_sjf.resposta,   m_prioridade.resposta]
    espera     = [m_rr.espera,     m_fcfs.espera,     m_sjf.espera,     m_prioridade.espera]
    throughput = [m_rr.vazao,      m_fcfs.vazao,      m_sjf.vazao,      m_prioridade.vazao]

    default(titlefontsize=30, labelfontsize=30, tickfontsize=30)
    plot(
        bar(algoritmos, turnaround,
            title="Tempo de Turnaround Médio",
            legend=false,
            ylabel="Tempo (ms)",
            fillcolor=:skyblue),

        bar(algoritmos, espera,
            title="Tempo de Espera Médio",
            legend=false,
            ylabel="Tempo (ms)",
            fillcolor=:coral),

        bar(algoritmos, resposta,
            title="Tempo de Resposta Médio",
            legend=false,
            ylabel="Tempo (ms)",
            fillcolor=:mediumseagreen),

        bar(algoritmos, throughput,
            title="Throughput",
            legend=false,
            ylabel="Processos (s)",
            fillcolor=:purple),

        layout = (4, 1),
        size = (2000, 2000),
        margin = 10Plots.mm
    )

    end