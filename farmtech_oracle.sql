-- ============================================================
-- FarmTech Solutions – Fase 3 | Banco de Dados Oracle
-- Aluno: Kauan Maciel Forgiarini | RM574005
-- FIAP – Inteligência Artificial | Cap 1 – Fase 3
-- ============================================================

-- ============================================================
-- PARTE 1: CRIAÇÃO DA TABELA (DDL)
-- Execute ANTES de importar o CSV pelo SQL Developer
-- ============================================================

-- Remove a tabela se já existir (evita erro na recriação)
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE SENSOR_FARMTECH';
EXCEPTION
   WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE SENSOR_FARMTECH (
    ID                  NUMBER(5)       PRIMARY KEY,
    TIMESTAMP_LEITURA   VARCHAR2(20)    NOT NULL,
    CULTURA             VARCHAR2(30)    DEFAULT 'Soja',
    N_PRESENTE          NUMBER(1)       CHECK (N_PRESENTE IN (0,1)),
    P_PRESENTE          NUMBER(1)       CHECK (P_PRESENTE IN (0,1)),
    K_PRESENTE          NUMBER(1)       CHECK (K_PRESENTE IN (0,1)),
    PH_SOLO             NUMBER(4,2)     CHECK (PH_SOLO BETWEEN 0 AND 14),
    UMIDADE_SOLO_PCT    NUMBER(5,1)     CHECK (UMIDADE_SOLO_PCT BETWEEN 0 AND 100),
    TEMPERATURA_C       NUMBER(5,1),
    CHUVA_PREVISTA_MM   NUMBER(6,1),
    BOMBA_LIGADA        NUMBER(1)       CHECK (BOMBA_LIGADA IN (0,1)),
    MOTIVO_DECISAO      VARCHAR2(50)
);

COMMENT ON TABLE  SENSOR_FARMTECH              IS 'Leituras dos sensores ESP32 – FarmTech Solutions Fase 2/3';
COMMENT ON COLUMN SENSOR_FARMTECH.N_PRESENTE   IS '1=Nitrogênio presente, 0=ausente';
COMMENT ON COLUMN SENSOR_FARMTECH.P_PRESENTE   IS '1=Fósforo presente, 0=ausente';
COMMENT ON COLUMN SENSOR_FARMTECH.K_PRESENTE   IS '1=Potássio presente, 0=ausente';
COMMENT ON COLUMN SENSOR_FARMTECH.PH_SOLO      IS 'pH simulado via LDR (0–14)';
COMMENT ON COLUMN SENSOR_FARMTECH.UMIDADE_SOLO_PCT IS 'Umidade simulada via DHT22 (%)';
COMMENT ON COLUMN SENSOR_FARMTECH.BOMBA_LIGADA IS '1=Relé azul ativado, 0=desligado';

-- ============================================================
-- PARTE 2: CONSULTAS SQL (após importação do CSV)
-- ============================================================

-- ── QUERY 1: Visualizar todos os dados ───────────────────────
-- Mais simples e obrigatória conforme enunciado
SELECT * FROM SENSOR_FARMTECH
ORDER BY ID;


-- ── QUERY 2: Contagem geral de leituras e status da bomba ────
SELECT
    COUNT(*)                                    AS TOTAL_LEITURAS,
    SUM(BOMBA_LIGADA)                           AS VEZES_BOMBA_LIGADA,
    COUNT(*) - SUM(BOMBA_LIGADA)                AS VEZES_BOMBA_DESLIGADA,
    ROUND(AVG(BOMBA_LIGADA) * 100, 1)           AS PCT_TEMPO_IRRIGANDO
FROM SENSOR_FARMTECH;


-- ── QUERY 3: Estatísticas dos sensores ───────────────────────
SELECT
    ROUND(AVG(PH_SOLO), 2)            AS MEDIA_PH,
    ROUND(MIN(PH_SOLO), 2)            AS MIN_PH,
    ROUND(MAX(PH_SOLO), 2)            AS MAX_PH,
    ROUND(AVG(UMIDADE_SOLO_PCT), 1)   AS MEDIA_UMIDADE_PCT,
    ROUND(MIN(UMIDADE_SOLO_PCT), 1)   AS MIN_UMIDADE_PCT,
    ROUND(MAX(UMIDADE_SOLO_PCT), 1)   AS MAX_UMIDADE_PCT,
    ROUND(AVG(TEMPERATURA_C), 1)      AS MEDIA_TEMP_C,
    ROUND(AVG(CHUVA_PREVISTA_MM), 2)  AS MEDIA_CHUVA_MM
FROM SENSOR_FARMTECH;


-- ── QUERY 4: Motivos pelos quais a bomba NÃO foi ligada ──────
SELECT
    MOTIVO_DECISAO,
    COUNT(*)                              AS OCORRENCIAS,
    ROUND(COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM SENSOR_FARMTECH), 1) AS PERCENTUAL
FROM SENSOR_FARMTECH
GROUP BY MOTIVO_DECISAO
ORDER BY OCORRENCIAS DESC;


-- ── QUERY 5: Leituras com pH fora da faixa ideal (5.5–7.0) ──
SELECT
    ID,
    TIMESTAMP_LEITURA,
    PH_SOLO,
    UMIDADE_SOLO_PCT,
    BOMBA_LIGADA,
    MOTIVO_DECISAO
FROM SENSOR_FARMTECH
WHERE PH_SOLO < 5.5 OR PH_SOLO > 7.0
ORDER BY PH_SOLO;


-- ── QUERY 6: Leituras onde N e K estavam ausentes ────────────
SELECT
    ID,
    TIMESTAMP_LEITURA,
    N_PRESENTE,
    P_PRESENTE,
    K_PRESENTE,
    PH_SOLO,
    UMIDADE_SOLO_PCT,
    BOMBA_LIGADA
FROM SENSOR_FARMTECH
WHERE N_PRESENTE = 0 AND K_PRESENTE = 0
ORDER BY ID;


-- ── QUERY 7: Leituras que acionaram a irrigação ──────────────
SELECT
    ID,
    TIMESTAMP_LEITURA,
    PH_SOLO,
    UMIDADE_SOLO_PCT,
    TEMPERATURA_C,
    CHUVA_PREVISTA_MM
FROM SENSOR_FARMTECH
WHERE BOMBA_LIGADA = 1
ORDER BY UMIDADE_SOLO_PCT ASC;


-- ── QUERY 8: Análise por dia (agrupamento temporal) ──────────
SELECT
    SUBSTR(TIMESTAMP_LEITURA, 1, 10)    AS DIA,
    COUNT(*)                            AS LEITURAS,
    SUM(BOMBA_LIGADA)                   AS ACIONAMENTOS_BOMBA,
    ROUND(AVG(PH_SOLO), 2)             AS MEDIA_PH,
    ROUND(AVG(UMIDADE_SOLO_PCT), 1)    AS MEDIA_UMIDADE
FROM SENSOR_FARMTECH
GROUP BY SUBSTR(TIMESTAMP_LEITURA, 1, 10)
ORDER BY DIA;


-- ── QUERY 9: Condições extremas – umidade crítica (<40%) ─────
SELECT
    ID,
    TIMESTAMP_LEITURA,
    UMIDADE_SOLO_PCT,
    PH_SOLO,
    BOMBA_LIGADA,
    MOTIVO_DECISAO
FROM SENSOR_FARMTECH
WHERE UMIDADE_SOLO_PCT < 40
ORDER BY UMIDADE_SOLO_PCT ASC;


-- ── QUERY 10: View resumida para o dashboard Python ──────────
CREATE OR REPLACE VIEW VW_FARMTECH_RESUMO AS
SELECT
    ID,
    TIMESTAMP_LEITURA,
    PH_SOLO,
    UMIDADE_SOLO_PCT,
    TEMPERATURA_C,
    CHUVA_PREVISTA_MM,
    BOMBA_LIGADA,
    MOTIVO_DECISAO,
    CASE
        WHEN PH_SOLO BETWEEN 5.5 AND 7.0 THEN 'IDEAL'
        WHEN PH_SOLO < 5.5               THEN 'ACIDO'
        ELSE                                  'ALCALINO'
    END AS STATUS_PH,
    CASE
        WHEN UMIDADE_SOLO_PCT < 40  THEN 'CRITICA'
        WHEN UMIDADE_SOLO_PCT < 60  THEN 'BAIXA'
        WHEN UMIDADE_SOLO_PCT < 80  THEN 'ADEQUADA'
        ELSE                             'SATURADA'
    END AS STATUS_UMIDADE
FROM SENSOR_FARMTECH;

-- Consultar a view
SELECT * FROM VW_FARMTECH_RESUMO ORDER BY ID;
