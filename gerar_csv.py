"""
FarmTech Solutions — Fase 3
Gerador de CSV com dados simulados dos sensores da Fase 2 (ESP32 / Wokwi)

Autor: Kauan Maciel Forgiarini — RM574005
FIAP — Inteligência Artificial — 2026
"""

import csv
import random
from datetime import datetime, timedelta

# Semente fixa para reprodutibilidade
random.seed(574005)

# Nome do arquivo de saída
ARQUIVO_SAIDA = "dados_sensores.csv"

# Período de simulação: 30 dias com leituras a cada 3 minutos
DATA_INICIO = datetime(2025, 4, 1, 6, 0, 0)
INTERVALO_MINUTOS = 3
TOTAL_REGISTROS = 300  # ~15 horas de dados (leituras diurnas)


def mapear_ph(ldr_valor: float) -> float:
    """Converte leitura do LDR (0–4095) para pH (0,0–14,0), igual ao firmware."""
    return round((ldr_valor / 4095.0) * 14.0, 2)


def deve_irrigar(umidade: float, ph: float, chuva: float,
                 nutriente_n: int, nutriente_k: int) -> int:
    """Replica a lógica de decisão do firmware C/C++ da Fase 2."""
    if chuva > 5.0:
        return 0
    if umidade >= 80.0:
        return 0
    if ph < 5.5 or ph > 7.0:
        return 0
    if umidade < 60.0 and (nutriente_n == 1 or nutriente_k == 1):
        return 1
    return 0


def gerar_registros():
    registros = []
    data_hora = DATA_INICIO

    for i in range(1, TOTAL_REGISTROS + 1):
        # Simula variação realista dos sensores
        umidade = round(random.gauss(62, 12), 1)
        umidade = max(30.0, min(95.0, umidade))

        temperatura = round(random.gauss(26, 4), 1)
        temperatura = max(15.0, min(40.0, temperatura))

        ldr_valor = random.uniform(1400, 2200)  # Faixa que gera pH 4,8–7,5
        ph = mapear_ph(ldr_valor)

        nutriente_n = random.choice([0, 1, 1])   # 66% de chance de presente
        nutriente_p = random.choice([0, 1])
        nutriente_k = random.choice([0, 1, 1])

        # Chuva: maioria dos registros sem chuva, alguns com
        chuva = round(random.choices(
            [0.0, random.uniform(0.5, 15.0)],
            weights=[80, 20]
        )[0], 1)

        bomba = deve_irrigar(umidade, ph, chuva, nutriente_n, nutriente_k)

        registros.append({
            "ID": i,
            "DATA_HORA": data_hora.strftime("%Y-%m-%d %H:%M"),
            "UMIDADE_PCT": umidade,
            "TEMPERATURA_C": temperatura,
            "PH_SOLO": ph,
            "NUTRIENTE_N": nutriente_n,
            "NUTRIENTE_P": nutriente_p,
            "NUTRIENTE_K": nutriente_k,
            "CHUVA_MM": chuva,
            "BOMBA_LIGADA": bomba,
        })

        data_hora += timedelta(minutes=INTERVALO_MINUTOS)

    return registros


def main():
    registros = gerar_registros()

    colunas = [
        "ID", "DATA_HORA", "UMIDADE_PCT", "TEMPERATURA_C",
        "PH_SOLO", "NUTRIENTE_N", "NUTRIENTE_P", "NUTRIENTE_K",
        "CHUVA_MM", "BOMBA_LIGADA"
    ]

    with open(ARQUIVO_SAIDA, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=colunas)
        writer.writeheader()
        writer.writerows(registros)

    total_irrigacoes = sum(r["BOMBA_LIGADA"] for r in registros)
    print(f"✅ Arquivo '{ARQUIVO_SAIDA}' gerado com sucesso!")
    print(f"   Total de registros : {len(registros)}")
    print(f"   Irrigações ativadas: {total_irrigacoes} "
          f"({total_irrigacoes/len(registros)*100:.1f}%)")
    print(f"\nPrimeiros 3 registros:")
    for r in registros[:3]:
        print(f"  {r}")


if __name__ == "__main__":
    main()
