
-- ====================================================================
-- SCRIPT CORRIGIDO PARA POSTGRESQL / POWER BI
-- Projeto Integrador - AutoMax
-- Baseado no arquivo banco.txt enviado pelo usuário.
-- ====================================================================
-- Objetivo:
-- 1) Criar o banco com nomes/relacionamentos mais consistentes.
-- 2) Evitar erros comuns no Power BI: relacionamentos ambíguos,
--    chaves inconsistentes, sequência SERIAL desatualizada e campos
--    difíceis de consumir.
-- 3) Criar views prontas para o Power BI.
--
-- Como usar:
-- - Crie o banco manualmente no PostgreSQL, por exemplo: projeto_integrador.
-- - Conecte-se nesse banco pelo pgAdmin/DBeaver.
-- - Execute este script inteiro.
-- - No Power BI, prefira carregar as views que começam com vw_powerbi_.
-- ====================================================================

BEGIN;

-- --------------------------------------------------------------------
-- LIMPEZA PARA PERMITIR REEXECUÇÃO DO SCRIPT
-- --------------------------------------------------------------------
DROP VIEW IF EXISTS vw_powerbi_movimentacoes CASCADE;
DROP VIEW IF EXISTS vw_powerbi_alerta_estoque CASCADE;
DROP VIEW IF EXISTS vw_powerbi_calendario CASCADE;
DROP VIEW IF EXISTS vw_qualidade_dados CASCADE;

DROP TABLE IF EXISTS Registros CASCADE;
DROP TABLE IF EXISTS Estoque CASCADE;
DROP TABLE IF EXISTS Produto CASCADE;
DROP TABLE IF EXISTS Prateleira_Corredor CASCADE;
DROP TABLE IF EXISTS Fornecedor CASCADE;
DROP TABLE IF EXISTS Funcionario CASCADE;
DROP TABLE IF EXISTS Categoria CASCADE;
DROP TABLE IF EXISTS Cliente CASCADE;
DROP TABLE IF EXISTS Tipo_Movimentacao CASCADE;
DROP TABLE IF EXISTS Marca CASCADE;
DROP TABLE IF EXISTS Cidade CASCADE;
DROP TABLE IF EXISTS Prateleira CASCADE;
DROP TABLE IF EXISTS Corredor CASCADE;
DROP TABLE IF EXISTS Cargo CASCADE;

-- --------------------------------------------------------------------
-- 1. CRIAÇÃO DAS TABELAS
-- Observação: PostgreSQL transforma nomes não-aspados em minúsculo.
-- Mantive nomes parecidos com o projeto original, mas corrigi o erro
-- Id_Prateleria_Corredor -> id_Prateleira_Corredor.
-- --------------------------------------------------------------------

CREATE TABLE Cargo(
    id_Cargo SERIAL PRIMARY KEY,
    Nome_Cargo VARCHAR(255) NOT NULL,
    observacoes VARCHAR(255),
    CONSTRAINT uq_Cargo_Nome UNIQUE (Nome_Cargo)
);

CREATE TABLE Funcionario(
    id_Funcionario SERIAL PRIMARY KEY,
    Nome_Funcionario VARCHAR(255) NOT NULL,
    fk_cargo INTEGER NOT NULL,

    CONSTRAINT fk_Funcionario_Cargo
        FOREIGN KEY (fk_cargo) REFERENCES Cargo(id_Cargo)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Corredor(
    id_Corredor SERIAL PRIMARY KEY,
    Nome_Corredor VARCHAR(255) NOT NULL,
    observacoes VARCHAR(255),
    CONSTRAINT uq_Corredor_Nome UNIQUE (Nome_Corredor)
);

CREATE TABLE Prateleira(
    id_Prateleira SERIAL PRIMARY KEY,
    Nome_Prateleira VARCHAR(255) NOT NULL,
    observacoes VARCHAR(255),
    CONSTRAINT uq_Prateleira_Nome UNIQUE (Nome_Prateleira)
);

CREATE TABLE Prateleira_Corredor(
    id_Prateleira_Corredor SERIAL PRIMARY KEY,
    fk_Prateleira INTEGER NOT NULL,
    fk_Corredor INTEGER NOT NULL,

    CONSTRAINT fk_Prateleira_Corredor_Prateleira
        FOREIGN KEY (fk_Prateleira) REFERENCES Prateleira(id_Prateleira)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_Prateleira_Corredor_Corredor
        FOREIGN KEY (fk_Corredor) REFERENCES Corredor(id_Corredor)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_Prateleira_Corredor UNIQUE (fk_Prateleira, fk_Corredor)
);

CREATE TABLE Cidade(
    id_Cidade SERIAL PRIMARY KEY,
    Nome_Estado VARCHAR(50) NOT NULL,
    Nome_Cidade VARCHAR(100) NOT NULL,
    Nome_Pais VARCHAR(50) NOT NULL DEFAULT 'Brazil',
    observacoes VARCHAR(255),
    CONSTRAINT uq_Cidade UNIQUE (Nome_Estado, Nome_Cidade, Nome_Pais)
);

CREATE TABLE Marca(
    id_Marca SERIAL PRIMARY KEY,
    Nome_Marca VARCHAR(255) NOT NULL,
    observacoes VARCHAR(255),
    CONSTRAINT uq_Marca_Nome UNIQUE (Nome_Marca)
);

CREATE TABLE Tipo_Movimentacao(
    id_Tipo_Movimentacao SERIAL PRIMARY KEY,
    Tipo_Movimentacao VARCHAR(255) NOT NULL,
    observacoes VARCHAR(255),
    CONSTRAINT uq_Tipo_Movimentacao UNIQUE (Tipo_Movimentacao)
);

CREATE TABLE Cliente(
    id_Cliente SERIAL PRIMARY KEY,
    Nome_Cliente VARCHAR(255) NOT NULL,
    observacoes VARCHAR(255),
    CONSTRAINT uq_Cliente_Nome UNIQUE (Nome_Cliente)
);

CREATE TABLE Categoria(
    Id_Categoria SERIAL PRIMARY KEY,
    Nome_Categoria VARCHAR(255) NOT NULL,
    observacoes VARCHAR(255),
    CONSTRAINT uq_Categoria_Nome UNIQUE (Nome_Categoria)
);

CREATE TABLE Fornecedor(
    Id_Fornecedor SERIAL PRIMARY KEY,
    Nome_Fornecedor VARCHAR(255) NOT NULL,
    fk_Cidade INTEGER NOT NULL,
    observacoes VARCHAR(255),

    CONSTRAINT fk_Fornecedor_Cidade
        FOREIGN KEY (fk_Cidade) REFERENCES Cidade(id_Cidade)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_Fornecedor_Nome UNIQUE (Nome_Fornecedor)
);

CREATE TABLE Produto(
    id_Produto SERIAL PRIMARY KEY,
    Cod_Produto VARCHAR(20) NOT NULL,
    Nome_Produto VARCHAR(255) NOT NULL,
    fk_Categoria INTEGER NOT NULL,
    fk_Fornecedor INTEGER NOT NULL,
    fk_Marca INTEGER NOT NULL,
    observacoes VARCHAR(255),

    CONSTRAINT fk_Produto_Categoria
        FOREIGN KEY (fk_Categoria) REFERENCES Categoria(Id_Categoria)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_Produto_Fornecedor
        FOREIGN KEY (fk_Fornecedor) REFERENCES Fornecedor(Id_Fornecedor)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_Produto_Marca
        FOREIGN KEY (fk_Marca) REFERENCES Marca(id_Marca)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Cod_Produto NÃO foi deixado como UNIQUE porque a base original possui
    -- códigos repetidos com produtos/categorias/marcas diferentes.
    -- Para relacionamento no Power BI, use sempre id_Produto.
    CONSTRAINT ck_Produto_Codigo_Nao_Vazio CHECK (length(trim(Cod_Produto)) > 0)
);

CREATE TABLE Estoque(
    id_Estoque SERIAL PRIMARY KEY,
    Estoque_minimo INTEGER NOT NULL,
    Estoque_maximo INTEGER NOT NULL,
    Estoque_atual INTEGER NOT NULL,
    fk_Produto INTEGER NOT NULL,
    Observacoes VARCHAR(255),

    CONSTRAINT fk_Estoque_Produto
        FOREIGN KEY (fk_Produto) REFERENCES Produto(id_Produto)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT ck_Estoque_Minimo_Positive CHECK (Estoque_minimo >= 0),
    CONSTRAINT ck_Estoque_Maximo_Positive CHECK (Estoque_maximo >= 0),
    CONSTRAINT ck_Estoque_Atual_Positive CHECK (Estoque_atual >= 0),
    CONSTRAINT ck_Estoque_Maximo_Maior_Minimo CHECK (Estoque_maximo >= Estoque_minimo)
);

CREATE TABLE Registros(
    id_Registro SERIAL PRIMARY KEY,
    fk_Cliente INTEGER NOT NULL,
    fk_Cidade_Cliente INTEGER NOT NULL,
    fk_Cidade_Fornecedor INTEGER NOT NULL,
    fk_Fornecedor INTEGER NOT NULL,
    Quantidade INTEGER NOT NULL,
    Data_Movimentacao DATE NOT NULL,
    valor_unitario NUMERIC(12,2) NOT NULL,
    fk_Estoque INTEGER NOT NULL,
    Observacoes VARCHAR(255),
    fk_Produto INTEGER NOT NULL,
    fk_Prateleira_Corredor INTEGER NOT NULL,
    fk_Tipo_Movimentacao INTEGER NOT NULL,
    fk_Funcionario INTEGER NOT NULL,

    CONSTRAINT fk_Registros_Funcionario
        FOREIGN KEY (fk_Funcionario) REFERENCES Funcionario(id_Funcionario)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_Registros_Tipo_Movimentacao
        FOREIGN KEY (fk_Tipo_Movimentacao) REFERENCES Tipo_Movimentacao(id_Tipo_Movimentacao)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_Registros_Prateleira_Corredor
        FOREIGN KEY (fk_Prateleira_Corredor) REFERENCES Prateleira_Corredor(id_Prateleira_Corredor)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_Registros_Cidade_Cliente
        FOREIGN KEY (fk_Cidade_Cliente) REFERENCES Cidade(id_Cidade)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_Registros_Cidade_Fornecedor
        FOREIGN KEY (fk_Cidade_Fornecedor) REFERENCES Cidade(id_Cidade)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_Registros_Fornecedor
        FOREIGN KEY (fk_Fornecedor) REFERENCES Fornecedor(id_Fornecedor)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_Registros_Cliente
        FOREIGN KEY (fk_Cliente) REFERENCES Cliente(id_Cliente)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_Registros_Estoque
        FOREIGN KEY (fk_Estoque) REFERENCES Estoque(id_Estoque)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_Registros_Produto
        FOREIGN KEY (fk_Produto) REFERENCES Produto(id_Produto)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT ck_Registros_Quantidade_Nao_Negativa CHECK (Quantidade >= 0),
    CONSTRAINT ck_Registros_Valor_Unitario_Nao_Negativo CHECK (valor_unitario >= 0)
);


-- ====================================================================
-- 2. INSERTS (DADOS)
-- ====================================================================

-- STREAMING_CHUNK:Inserindo dados nas dimensões simples...
INSERT INTO Cargo (id_Cargo, Nome_Cargo, observacoes) VALUES 
(1, 'Estoquista', NULL), (2, 'Comprador', NULL), (3, 'Supervisor', NULL);

INSERT INTO Corredor (id_Corredor, Nome_Corredor, observacoes) VALUES 
(1, 'C6', NULL), (2, 'C3', NULL), (3, 'C5', NULL), (4, 'C9', NULL), 
(5, 'C1', NULL), (6, 'C8', NULL), (7, 'C10', NULL), (8, 'C7', NULL), 
(9, 'C2', NULL), (10, 'C4', NULL);

INSERT INTO Prateleira (id_Prateleira, Nome_Prateleira, observacoes) VALUES 
(1, 'P18', NULL), (2, 'P26', NULL), (3, 'P1', NULL), (4, 'P6', NULL), 
(5, 'P17', NULL), (6, 'P15', NULL), (7, 'P29', NULL), (8, 'P25', NULL), 
(9, 'P10', NULL), (10, 'P30', NULL), (11, 'P11', NULL), (12, 'P4', NULL), 
(13, 'P19', NULL), (14, 'P8', NULL), (15, 'P27', NULL), (16, 'P14', NULL), 
(17, 'P13', NULL), (18, 'P7', NULL), (19, 'P28', NULL), (20, 'P22', NULL), 
(21, 'P2', NULL), (22, 'P20', NULL), (23, 'P5', NULL), (24, 'P16', NULL), 
(25, 'P23', NULL), (26, 'P21', NULL), (27, 'P24', NULL), (28, 'P3', NULL), 
(29, 'P12', NULL), (30, 'P9', NULL);

INSERT INTO Cidade (id_Cidade, Nome_Estado, Nome_Cidade, Nome_Pais, observacoes) VALUES 
(1, 'PR', 'Londrina', 'Brazil', NULL), (2, 'PR', 'Araucaria', 'Brazil', NULL), 
(3, 'PR', 'Cascavel', 'Brazil', NULL), (4, 'PR', 'Ponta Grossa', 'Brazil', NULL), 
(5, 'PR', 'Curitiba', 'Brazil', NULL), (6, 'PR', 'Maringa', 'Brazil', NULL);

INSERT INTO Marca (id_Marca, Nome_Marca, observacoes) VALUES 
(1, 'Bosch', NULL), (2, 'Monroe', NULL), (3, 'Fras-le', NULL), 
(4, 'NGK', NULL), (5, 'Valeo', NULL), (6, 'Cofap', NULL);

INSERT INTO Tipo_Movimentacao (id_Tipo_Movimentacao, Tipo_Movimentacao, observacoes) VALUES 
(1, 'Saída', NULL), (2, 'Entrada', NULL);

INSERT INTO Cliente (id_Cliente, Nome_Cliente, observacoes) VALUES 
(1, 'Concessionaria Alpha', NULL), (2, 'Oficina Curitiba', NULL), 
(3, 'Garage Prime', NULL), (4, 'Auto Pecas Lima', NULL), 
(5, 'Oficina Parana', NULL), (6, 'Auto Center Sul', NULL), 
(7, 'Mecanica Rapida', NULL), (8, 'Mecanica Express', NULL);

INSERT INTO Categoria (Id_Categoria, Nome_Categoria, observacoes) VALUES 
(1, 'Eletrica', NULL), (2, 'Freios', NULL), (3, 'Transmissao', NULL), 
(4, 'Arrefecimento', NULL), (5, 'Suspensao', NULL), (6, 'Motor', NULL), 
(7, 'Sistema de Freios', NULL);

-- STREAMING_CHUNK:Inserindo tabelas com dependências (Funcionário e Fornecedor)...
INSERT INTO Funcionario (id_Funcionario, Nome_Funcionario, fk_cargo) VALUES 
(1, 'Joao Santos', 2), (2, 'Lucas Pereira', 1), (3, 'Marcos Rocha', 2), 
(4, 'Juliana Ribeiro', 2), (5, 'Ana Costa', 3), (6, 'Carlos Silva', 1), 
(7, 'Fernanda Alves', 3), (8, 'Rafael Lima', 2);

INSERT INTO Fornecedor (Id_Fornecedor, Nome_Fornecedor, fk_Cidade, observacoes) VALUES 
(1, 'Auto Center Supply', 1, NULL), (2, 'Speed Parts', 2, NULL), 
(3, 'Auto Parts Brasil', 3, NULL), (4, 'Prime Autopecas', 4, NULL), 
(5, 'Distribuidora Master', 5, NULL), (6, 'Pecas Parana', 6, NULL), 
(7, 'Mecanica Sul', 5, NULL), (8, 'TecAuto', 4, NULL);

-- STREAMING_CHUNK:Inserindo Produtos e Tabela de ligação Prateleira_Corredor...
INSERT INTO Produto (id_Produto, Cod_Produto, Nome_Produto, fk_Categoria, fk_Fornecedor, fk_Marca) VALUES 
(1, 'P1022', 'Filtro de Oleo', 1, 1, 1), (2, 'P1003', 'Past. Freio', 2, 2, 1), 
(3, 'P1039', 'Past. Freio', 1, 3, 2), (4, 'P1047', 'Filtro de Oleo', 3, 4, 1), 
(5, 'P1001', 'Past. Freio', 1, 5, 3), (6, 'P1049', 'Past. Freio', 4, 6, 4), 
(7, 'P1035', 'Filtro de Oleo', 3, 7, 3), (8, 'P1015', 'Filtro de Oleo', 4, 8, 5), 
(9, 'P1018', 'Past. Freio', 2, 1, 5), (10, 'P1046', 'Past. Freio', 4, 2, 5), 
(11, 'P1024', 'Filtro de Oleo', 4, 3, 4), (12, 'P1036', 'Past. Freio', 5, 4, 4), 
(13, 'P1016', 'Filtro de Oleo', 1, 5, 2), (14, 'P1046', 'Filtro de Oleo', 6, 6, 5), 
(15, 'P1018', 'Past. Freio', 1, 7, 5), (16, 'P1016', 'Past. Freio', 3, 8, 1), 
(17, 'P1012', 'Past. Freio', 2, 1, 3), (18, 'P1036', 'Past. Freio', 5, 2, 6), 
(19, 'P1027', 'Past. Freio', 3, 3, 6), (20, 'P1008', 'Past. Freio', 1, 4, 4), 
(21, 'P1024', 'Filtro de Oleo', 5, 5, 2), (22, 'P1029', 'Past. Freio', 6, 6, 1), 
(23, 'P1016', 'Radiador', 4, 7, 1), (24, 'P1009', 'Kit Embreagem', 5, 8, 1), 
(25, 'P1020', 'Disco de Freio', 4, 1, 5), (26, 'P1043', 'Filtro de Ar', 1, 2, 1), 
(27, 'P1045', 'Kit Embreagem', 1, 3, 1), (28, 'P1043', 'Sensor ABS', 3, 4, 2), 
(29, 'P1001', 'Amortecedor Dianteiro', 6, 5, 5), (30, 'P1042', 'Radiador', 4, 6, 2), 
(31, 'P1022', 'Rolamento de Roda', 3, 7, 2), (32, 'P1050', 'Filtro de Oleo', 3, 8, 4), 
(33, 'P1021', 'Radiador', 1, 1, 1), (34, 'P1043', 'Disco de Freio', 2, 2, 6), 
(35, 'P1044', 'Radiador', 2, 3, 1), (36, 'P1023', 'Bateria 70Ah', 2, 4, 6), 
(37, 'P1012', 'Correia Dentada', 2, 5, 6), (38, 'P1023', 'Past. Freio', 7, 6, 1), 
(39, 'P1024', 'Past. Freio', 7, 7, 6), (40, 'P1022', 'Bateria 70Ah', 7, 8, 4), 
(41, 'P1015', 'Radiador', 7, 1, 1), (42, 'P1038', 'Velas de Ignicao', 7, 2, 4), 
(43, 'P1040', 'Filtro de Oleo', 7, 3, 6), (44, 'P1044', 'Disco de Freio', 2, 4, 3), 
(45, 'P1048', 'Amortecedor Dianteiro', 2, 5, 2), (46, 'P1047', 'Filtro de Ar', 2, 6, 2), 
(47, 'P1010', 'Amortecedor Traseiro', 7, 7, 3), (48, 'P1037', 'Bateria 70Ah', 7, 8, 5), 
(49, 'P1049', 'Filtro de Oleo', 5, 1, 6), (50, 'P1015', 'Velas de Ignicao', 6, 2, 2), 
(51, 'P1002', 'Bomba de Combustivel', 2, 3, 3), (52, 'P1017', 'Filtro de Oleo', 3, 4, 2), 
(53, 'P1040', 'Rolamento de Roda', 6, 5, 1), (54, 'P1018', 'Sensor ABS', 1, 6, 4), 
(55, 'P1024', 'Disco de Freio', 6, 7, 5), (56, 'P1038', 'Kit Embreagem', 6, 8, 3), 
(57, 'P1041', 'Amortecedor Traseiro', 5, 1, 4), (58, 'P1009', 'Filtro de Ar', 3, 2, 5), 
(59, 'P1022', 'Bomba de Combustivel', 4, 3, 6), (60, 'P1048', 'Correia Dentada', 5, 4, 4), 
(61, 'P1036', 'Radiador', 3, 5, 6), (62, 'P1016', 'Filtro de Ar', 5, 6, 5), 
(63, 'P1040', 'Radiador', 4, 7, 6), (64, 'P1009', 'Bateria 60Ah', 5, 8, 2), 
(65, 'P1021', 'Rolamento de Roda', 1, 1, 1), (66, 'P1044', 'Amortecedor Traseiro', 4, 2, 6), 
(67, 'P1019', 'Disco de Freio', 2, 3, 1), (68, 'P1049', 'Disco de Freio', 1, 4, 6), 
(69, 'P1047', 'Kit Embreagem', 6, 5, 6), (70, 'P1002', 'Rolamento de Roda', 3, 6, 5), 
(71, 'P1007', 'Bateria 70Ah', 1, 7, 1), (72, 'P1032', 'Past. Freio', 4, 8, 1), 
(73, 'P1014', 'Sensor ABS', 2, 1, 3), (74, 'P1008', 'Sensor ABS', 3, 2, 5), 
(75, 'P1038', 'Correia Dentada', 3, 3, 1), (76, 'P1025', 'Bateria 60Ah', 1, 4, 6), 
(77, 'P1015', 'Past. Freio', 3, 5, 3), (78, 'P1042', 'Correia Dentada', 1, 6, 1), 
(79, 'P1022', 'Filtro de Ar', 2, 7, 3), (80, 'P1008', 'Amortecedor Traseiro', 6, 8, 2), 
(81, 'P1021', 'Amortecedor Traseiro', 3, 1, 2), (82, 'P1032', 'Velas de Ignicao', 4, 2, 1), 
(83, 'P1043', 'Radiador', 6, 3, 2), (84, 'P1016', 'Filtro de Oleo', 5, 4, 3), 
(85, 'P1031', 'Velas de Ignicao', 2, 5, 3), (86, 'P1041', 'Correia Dentada', 5, 6, 1), 
(87, 'P1048', 'Bomba de Combustivel', 1, 7, 2), (88, 'P1021', 'Rolamento de Roda', 5, 8, 6), 
(89, 'P1001', 'Bomba de Combustivel', 2, 1, 4), (90, 'P1034', 'Radiador', 5, 2, 6), 
(91, 'P1007', 'Amortecedor Dianteiro', 6, 3, 1), (92, 'P1028', 'Velas de Ignicao', 6, 4, 3), 
(93, 'P1029', 'Sensor ABS', 5, 5, 5), (94, 'P1003', 'Correia Dentada', 5, 6, 6), 
(95, 'P1011', 'Disco de Freio', 3, 7, 2), (96, 'P1043', 'Rolamento de Roda', 2, 8, 5), 
(97, 'P1045', 'Radiador', 4, 1, 5), (98, 'P1012', 'Amortecedor Dianteiro', 4, 2, 4), 
(99, 'P1024', 'Velas de Ignicao', 3, 3, 2), (100, 'P1007', 'Bateria 60Ah', 5, 4, 5), 
(101, 'P1005', 'Amortecedor Dianteiro', 4, 5, 5), (102, 'P1017', 'Radiador', 2, 6, 4), 
(103, 'P1016', 'Bateria 70Ah', 3, 7, 3), (104, 'P1039', 'Radiador', 5, 8, 2), 
(105, 'P1031', 'Filtro de Oleo', 2, 1, 4), (106, 'P1030', 'Filtro de Oleo', 3, 2, 5), 
(107, 'P1020', 'Velas de Ignicao', 6, 3, 6), (108, 'P1024', 'Bateria 70Ah', 3, 4, 4), 
(109, 'P1005', 'Sensor ABS', 2, 5, 6), (110, 'P1049', 'Bateria 60Ah', 4, 6, 3), 
(111, 'P1009', 'Amortecedor Dianteiro', 1, 7, 5), (112, 'P1018', 'Bateria 70Ah', 6, 8, 5), 
(113, 'P1001', 'Rolamento de Roda', 5, 1, 5), (114, 'P1045', 'Bomba de Combustivel', 5, 2, 5), 
(115, 'P1030', 'Sensor ABS', 3, 3, 3), (116, 'P1016', 'Correia Dentada', 6, 4, 3), 
(117, 'P1048', 'Velas de Ignicao', 2, 5, 6), (118, 'P1008', 'Velas de Ignicao', 1, 6, 2), 
(119, 'P1039', 'Amortecedor Dianteiro', 5, 7, 3), (120, 'P1041', 'Sensor ABS', 6, 8, 6), 
(121, 'P1046', 'Velas de Ignicao', 6, 1, 5), (122, 'P1027', 'Amortecedor Dianteiro', 2, 2, 4), 
(123, 'P1016', 'Sensor ABS', 2, 3, 5), (124, 'P1031', 'Correia Dentada', 2, 4, 1), 
(125, 'P1009', 'Bomba de Combustivel', 6, 5, 5), (126, 'P1013', 'Bateria 70Ah', 5, 6, 5), 
(127, 'P1026', 'Disco de Freio', 4, 7, 3), (128, 'P1042', 'Bateria 70Ah', 2, 8, 1), 
(129, 'P1038', 'Amortecedor Traseiro', 6, 1, 3), (130, 'P1018', 'Disco de Freio', 4, 2, 4), 
(131, 'P1032', 'Bateria 60Ah', 4, 3, 4), (132, 'P1027', 'Correia Dentada', 4, 4, 3), 
(133, 'P1044', 'Amortecedor Dianteiro', 1, 5, 2), (134, 'P1021', 'Amortecedor Dianteiro', 1, 6, 1), 
(135, 'P1006', 'Velas de Ignicao', 2, 7, 2), (136, 'P1045', 'Radiador', 3, 8, 2), 
(137, 'P1008', 'Radiador', 1, 1, 3), (138, 'P1037', 'Amortecedor Traseiro', 5, 2, 5), 
(139, 'P1025', 'Past. Freio', 1, 3, 1), (140, 'P1041', 'Amortecedor Dianteiro', 4, 4, 1), 
(141, 'P1016', 'Bateria 60Ah', 4, 5, 2), (142, 'P1049', 'Velas de Ignicao', 4, 6, 2), 
(143, 'P1003', 'Bateria 70Ah', 6, 7, 6), (144, 'P1034', 'Radiador', 6, 8, 3), 
(145, 'P1024', 'Bateria 70Ah', 2, 1, 2), (146, 'P1033', 'Filtro de Ar', 5, 2, 1), 
(147, 'P1003', 'Velas de Ignicao', 1, 3, 5), (148, 'P1014', 'Filtro de Ar', 1, 4, 5), 
(149, 'P1042', 'Filtro de Oleo', 4, 5, 3), (150, 'P1045', 'Filtro de Ar', 3, 6, 1), 
(151, 'P1035', 'Amortecedor Dianteiro', 3, 7, 1), (152, 'P1040', 'Correia Dentada', 3, 8, 5), 
(153, 'P1040', 'Bomba de Combustivel', 4, 1, 5), (154, 'P1003', 'Bateria 60Ah', 2, 2, 1), 
(155, 'P1037', 'Bateria 70Ah', 5, 3, 3), (156, 'P1001', 'Correia Dentada', 2, 4, 2), 
(157, 'P1014', 'Rolamento de Roda', 4, 5, 6), (158, 'P1011', 'Rolamento de Roda', 4, 6, 4), 
(159, 'P1025', 'Disco de Freio', 3, 7, 3), (160, 'P1040', 'Disco de Freio', 1, 8, 5), 
(161, 'P1049', 'Amortecedor Dianteiro', 6, 1, 6), (162, 'P1009', 'Filtro de Oleo', 1, 2, 5), 
(163, 'P1024', 'Correia Dentada', 1, 3, 6), (164, 'P1012', 'Sensor ABS', 1, 4, 5), 
(165, 'P1012', 'Kit Embreagem', 1, 5, 3), (166, 'P1035', 'Filtro de Ar', 4, 6, 5), 
(167, 'P1004', 'Bomba de Combustivel', 1, 7, 3), (168, 'P1035', 'Velas de Ignicao', 6, 8, 4), 
(169, 'P1040', 'Filtro de Oleo', 6, 1, 2), (170, 'P1045', 'Bomba de Combustivel', 5, 2, 1), 
(171, 'P1037', 'Rolamento de Roda', 2, 3, 6), (172, 'P1048', 'Bomba de Combustivel', 6, 4, 3), 
(173, 'P1028', 'Bateria 60Ah', 5, 5, 3), (174, 'P1015', 'Radiador', 6, 6, 4), 
(175, 'P1037', 'Radiador', 2, 7, 6), (176, 'P1027', 'Filtro de Ar', 6, 8, 2), 
(177, 'P1002', 'Filtro de Oleo', 2, 1, 3), (178, 'P1026', 'Filtro de Oleo', 6, 2, 4), 
(179, 'P1003', 'Amortecedor Traseiro', 2, 3, 3), (180, 'P1006', 'Amortecedor Traseiro', 1, 4, 2), 
(181, 'P1009', 'Bomba de Combustivel', 6, 5, 1), (182, 'P1026', 'Kit Embreagem', 5, 6, 4), 
(183, 'P1005', 'Velas de Ignicao', 3, 7, 5), (184, 'P1018', 'Past. Freio', 2, 8, 4), 
(185, 'P1010', 'Correia Dentada', 2, 1, 5), (186, 'P1034', 'Bateria 70Ah', 2, 2, 3), 
(187, 'P1024', 'Bateria 70Ah', 1, 3, 3), (188, 'P1005', 'Disco de Freio', 5, 4, 3), 
(189, 'P1003', 'Amortecedor Traseiro', 1, 5, 4), (190, 'P1032', 'Bateria 60Ah', 2, 6, 4), 
(191, 'P1045', 'Amortecedor Traseiro', 2, 7, 1), (192, 'P1033', 'Amortecedor Traseiro', 5, 8, 6), 
(193, 'P1024', 'Amortecedor Traseiro', 6, 1, 4), (194, 'P1050', 'Amortecedor Dianteiro', 6, 2, 2), 
(195, 'P1049', 'Sensor ABS', 6, 3, 2), (196, 'P1023', 'Radiador', 5, 4, 5), 
(197, 'P1015', 'Sensor ABS', 1, 5, 3), (198, 'P1011', 'Bomba de Combustivel', 6, 6, 2), 
(199, 'P1013', 'Past. Freio', 1, 7, 6), (200, 'P1021', 'Sensor ABS', 1, 8, 2), 
(201, 'P1030', 'Velas de Ignicao', 5, 1, 4), (202, 'P1046', 'Filtro de Oleo', 2, 2, 2), 
(203, 'P1030', 'Bateria 60Ah', 3, 3, 2), (204, 'P1031', 'Velas de Ignicao', 4, 4, 4), 
(205, 'P1048', 'Disco de Freio', 5, 5, 4), (206, 'P1047', 'Bateria 70Ah', 6, 6, 2), 
(207, 'P1040', 'Sensor ABS', 3, 7, 6), (208, 'P1005', 'Disco de Freio', 2, 8, 5), 
(209, 'P1012', 'Amortecedor Traseiro', 2, 1, 6), (210, 'P1007', 'Filtro de Oleo', 5, 2, 5), 
(211, 'P1012', 'Radiador', 2, 3, 3), (212, 'P1048', 'Amortecedor Traseiro', 6, 4, 5), 
(213, 'P1040', 'Rolamento de Roda', 2, 5, 4), (214, 'P1012', 'Kit Embreagem', 1, 6, 4), 
(215, 'P1042', 'Correia Dentada', 1, 7, 5), (216, 'P1048', 'Sensor ABS', 4, 8, 1), 
(217, 'P1037', 'Bateria 60Ah', 4, 1, 1), (218, 'P1004', 'Filtro de Ar', 4, 2, 2), 
(219, 'P1001', 'Bomba de Combustivel', 3, 3, 6), (220, 'P1020', 'Kit Embreagem', 4, 4, 4), 
(221, 'P1012', 'Amortecedor Dianteiro', 4, 5, 2), (222, 'P1024', 'Amortecedor Dianteiro', 5, 6, 1), 
(223, 'P1004', 'Kit Embreagem', 2, 7, 2), (224, 'P1050', 'Amortecedor Dianteiro', 2, 8, 1);

INSERT INTO Prateleira_Corredor (fk_Prateleira, fk_Corredor) VALUES 
(1, 1), (2, 2), (3, 1), (4, 3), (5, 4), (6, 2), (2, 5), (7, 2), (8, 3), (9, 6), 
(10, 3), (11, 7), (10, 8), (11, 8), (12, 3), (13, 6), (1, 6), (14, 8), (15, 4), (16, 8), 
(17, 9), (18, 1), (19, 6), (4, 5), (20, 2), (21, 5), (22, 5), (18, 4), (8, 5), (16, 3), 
(12, 7), (6, 9), (23, 5), (18, 5), (5, 2), (13, 7), (17, 7), (12, 10), (24, 5), (25, 8), 
(26, 2), (12, 5), (27, 8), (15, 8), (12, 2), (24, 7), (2, 6), (2, 8), (6, 1), (22, 7), 
(13, 2), (1, 10), (5, 8), (26, 5), (27, 10), (22, 2), (24, 2), (28, 2), (26, 4), (25, 7), 
(17, 1), (1, 8), (18, 10), (14, 7), (4, 10), (25, 9), (21, 6), (19, 7), (6, 10), (23, 8), 
(7, 5), (22, 4), (19, 5), (4, 2), (18, 3), (22, 1), (29, 8), (30, 4), (10, 9), (8, 7), 
(27, 1), (1, 2), (4, 7), (19, 1), (12, 9), (25, 6), (24, 10), (1, 5), (8, 8), (24, 8), 
(5, 6), (25, 10), (19, 8), (11, 2), (15, 9), (11, 1), (26, 6), (7, 4), (19, 3), (8, 1), 
(22, 3), (28, 1), (19, 10), (24, 3), (23, 9), (14, 9), (17, 8), (21, 1), (11, 6), (27, 6), 
(4, 1), (28, 6), (11, 5), (20, 10), (12, 6), (3, 2), (3, 9), (23, 4), (20, 7), (26, 7), 
(23, 10), (9, 10), (29, 4), (24, 6), (7, 3), (17, 3), (26, 8), (21, 8), (20, 9), (3, 6), 
(11, 10), (30, 5), (14, 10), (22, 8), (10, 6), (8, 10), (28, 8), (23, 1), (9, 2), (2, 9), 
(25, 4), (25, 5), (2, 7), (20, 3), (10, 5), (9, 5), (30, 1), (18, 6), (7, 1), (7, 6), 
(22, 6), (1, 4), (22, 9), (8, 2), (30, 7), (19, 9), (29, 2), (6, 6), (15, 5), (2, 1), 
(26, 1), (7, 9), (16, 7), (8, 6), (29, 5), (17, 5), (18, 2), (3, 3), (7, 8), (14, 1), 
(28, 10), (21, 9), (9, 8), (22, 10), (23, 6), (17, 2), (23, 2), (12, 8), (24, 4), (6, 7), 
(27, 4), (14, 2), (30, 10), (29, 9), (2, 10), (6, 4), (16, 4), (9, 9), (10, 1), (29, 10), 
(26, 10), (20, 5);

-- STREAMING_CHUNK:Inserindo dados de Estoque...
INSERT INTO Estoque (Estoque_minimo, Estoque_maximo, Estoque_atual, fk_Produto, Observacoes) VALUES 
(50, 500, 274, 4, NULL), (50, 500, 988, 139, NULL), (50, 500, 381, 3, NULL), (50, 500, 1383, 77, NULL), 
(50, 500, 623, 184, NULL), (50, 500, 0, 177, NULL), (50, 500, 455, 210, NULL), (50, 500, 623, 15, NULL), 
(50, 500, 272, 178, NULL), (50, 500, 606, 202, NULL), (50, 500, 524, 199, NULL), (50, 500, 1383, 41, NULL), 
(50, 500, 500, 27, NULL), (50, 500, 0, 208, NULL), (50, 500, 500, 150, NULL), (50, 500, 632, 200, NULL), 
(50, 500, 0, 111, NULL), (50, 500, 500, 136, NULL), (50, 500, 478, 31, NULL), (50, 500, 861, 68, NULL), 
(50, 500, 0, 143, NULL), (50, 500, 1470, 163, NULL), (50, 500, 1470, 108, NULL), (50, 500, 583, 204, NULL), 
(50, 500, 861, 49, NULL), (50, 500, 0, 188, NULL), (50, 500, 0, 221, NULL), (50, 500, 0, 218, NULL), 
(50, 500, 0, 179, NULL), (50, 500, 0, 126, NULL), (50, 500, 861, 142, NULL), (50, 500, 1357, 172, NULL), 
(50, 500, 0, 65, NULL), (50, 500, 0, 54, NULL), (50, 500, 0, 165, NULL), (50, 500, 0, 193, NULL), 
(50, 500, 0, 166, NULL), (50, 500, 0, 219, NULL), (50, 500, 1357, 60, NULL), (50, 500, 0, 175, NULL), 
(50, 500, 0, 203, NULL), (50, 500, 0, 209, NULL), (50, 500, 0, 67, NULL), (50, 500, 274, 69, NULL), 
(50, 500, 0, 113, NULL), (50, 500, 0, 128, NULL), (50, 500, 0, 197, NULL), (50, 500, 0, 164, NULL), 
(50, 500, 0, 124, NULL), (50, 500, 0, 76, NULL), (50, 500, 0, 79, NULL), (50, 500, 0, 180, NULL), 
(50, 500, 0, 82, NULL), (50, 500, 0, 92, NULL), (50, 500, 0, 198, NULL), (50, 500, 0, 171, NULL), 
(50, 500, 0, 89, NULL), (50, 500, 0, 224, NULL), (50, 500, 0, 95, NULL), (50, 500, 0, 196, NULL), 
(50, 500, 0, 122, NULL), (50, 500, 0, 100, NULL), (50, 500, 0, 174, NULL), (50, 500, 0, 187, NULL), 
(50, 500, 0, 117, NULL), (50, 500, 0, 207, NULL), (50, 500, 0, 173, NULL), (50, 500, 0, 153, NULL), 
(50, 500, 0, 132, NULL), (50, 500, 0, 119, NULL), (50, 500, 0, 183, NULL), (50, 500, 0, 205, NULL), 
(50, 500, 0, 190, NULL), (50, 500, 0, 211, NULL), (50, 500, 0, 212, NULL), (50, 500, 0, 206, NULL), 
(50, 500, 0, 215, NULL), (50, 500, 0, 217, NULL), (50, 500, 0, 156, NULL), (50, 500, 0, 213, NULL), 
(50, 500, 0, 161, NULL), (50, 500, 0, 181, NULL), (50, 500, 0, 220, NULL), (50, 500, 0, 191, NULL), 
(50, 500, 0, 216, NULL), (50, 500, 0, 223, NULL);

-- STREAMING_CHUNK:Inserindo a tabela Fato principal (Registros)...
INSERT INTO Registros (id_Registro, fk_Cliente, fk_Cidade_Cliente, fk_Cidade_Fornecedor, fk_Fornecedor, Quantidade, valor_unitario, fk_Funcionario, Data_Movimentacao, fk_Estoque, fk_Produto, fk_Prateleira_Corredor, fk_Tipo_Movimentacao) VALUES 
(1, 1, 1, 1, 1, 10, 578.00, 1, '2025-01-14', 57, 89, 1, 1),
(2, 2, 4, 2, 2, 2, 483.46, 1, '2025-01-01', 57, 89, 2, 2),
(3, 3, 2, 3, 3, 88, 789.68, 2, '2025-05-27', 3, 3, 3, 2),
(4, 4, 3, 4, 4, 96, 772.45, 3, '2025-05-18', 1, 4, 4, 2),
(5, 2, 4, 1, 2, 5, 295.76, 4, '2025-04-11', 57, 89, 5, 1),
(6, 5, 6, 5, 4, 40, 1488.06, 5, '2025-06-11', 57, 89, 6, 1),
(7, 3, 5, 5, 2, 28, 932.11, 6, '2025-04-01', 10, 202, 7, 1),
(8, 6, 2, 5, 3, 68, 1434.31, 4, '2025-05-20', 57, 89, 8, 1),
(9, 4, 1, 1, 5, 161, 99.88, 1, '2025-06-23', 57, 89, 9, 1),
(10, 5, 1, 6, 6, 111, 107.15, 3, '2025-05-17', 13, 27, 10, 1),
(11, 1, 1, 6, 6, 129, 170.59, 4, '2025-05-14', 57, 89, 11, 1),
(12, 4, 3, 1, 7, 130, 311.26, 7, '2025-03-24', 5, 184, 12, 2),
(13, 7, 3, 4, 6, 127, 1099.88, 8, '2025-05-18', 57, 89, 13, 1),
(14, 1, 4, 6, 4, 179, 883.17, 4, '2025-06-12', 57, 89, 14, 2),
(15, 4, 5, 6, 2, 107, 572.37, 6, '2025-03-29', 57, 89, 15, 2),
(16, 4, 1, 4, 1, 120, 866.69, 1, '2025-04-08', 57, 89, 16, 1),
(17, 8, 3, 2, 1, 13, 285.58, 4, '2025-06-26', 13, 27, 17, 1),
(18, 2, 6, 5, 5, 119, 763.61, 6, '2025-02-06', 10, 202, 18, 1),
(19, 2, 4, 1, 3, 128, 1015.55, 6, '2025-02-13', 5, 184, 19, 2),
(20, 6, 5, 5, 7, 114, 925.10, 1, '2025-04-30', 13, 27, 20, 1),
(21, 5, 4, 1, 2, 40, 747.43, 4, '2025-05-26', 57, 89, 21, 2),
(22, 5, 2, 5, 3, 188, 1331.84, 7, '2025-06-17', 57, 89, 22, 1),
(23, 2, 1, 4, 2, 131, 998.70, 7, '2025-04-03', 57, 89, 23, 1),
(24, 5, 5, 6, 6, 118, 1390.81, 1, '2025-05-02', 57, 89, 22, 2),
(25, 4, 5, 4, 8, 200, 1008.09, 1, '2025-05-11', 57, 89, 24, 2),
(26, 4, 4, 2, 2, 170, 615.93, 7, '2025-01-26', 57, 89, 25, 2),
(27, 6, 5, 6, 8, 23, 1017.79, 5, '2025-02-22', 13, 27, 26, 1),
(28, 4, 6, 1, 3, 108, 1465.12, 2, '2025-03-05', 57, 89, 27, 1),
(29, 6, 1, 2, 3, 21, 577.11, 2, '2025-06-26', 57, 89, 28, 1),
(30, 1, 6, 6, 4, 168, 1337.12, 2, '2025-02-22', 13, 27, 29, 2),
(31, 2, 3, 6, 3, 32, 1340.75, 2, '2025-02-17', 13, 27, 30, 1),
(32, 3, 6, 5, 3, 74, 1201.88, 4, '2025-05-22', 57, 89, 31, 1),
(33, 3, 6, 1, 3, 107, 326.34, 6, '2025-06-22', 57, 89, 30, 1),
(34, 2, 6, 3, 3, 146, 94.54, 2, '2025-01-17', 57, 89, 3, 1),
(35, 1, 4, 3, 3, 17, 1301.16, 3, '2025-02-21', 57, 89, 32, 2),
(36, 6, 2, 1, 3, 56, 148.19, 1, '2025-05-26', 13, 27, 33, 1),
(37, 7, 2, 5, 3, 86, 997.93, 3, '2025-01-13', 57, 89, 34, 1),
(38, 6, 4, 3, 3, 73, 625.30, 2, '2025-06-19', 57, 89, 35, 2),
(39, 1, 1, 6, 3, 96, 454.94, 6, '2025-06-17', 57, 89, 36, 1),
(40, 6, 4, 5, 3, 96, 1135.22, 8, '2025-01-11', 13, 27, 37, 2),
(41, 7, 6, 4, 3, 81, 1407.60, 4, '2025-05-15', 19, 31, 38, 1),
(42, 2, 6, 3, 3, 191, 1216.74, 3, '2025-01-11', 57, 89, 39, 2),
(43, 4, 4, 2, 3, 110, 1123.60, 1, '2025-06-23', 57, 89, 40, 1),
(44, 1, 2, 5, 3, 83, 1170.79, 4, '2025-04-29', 57, 89, 41, 1),
(45, 7, 3, 6, 3, 69, 1432.41, 5, '2025-05-01', 57, 89, 42, 1),
(46, 6, 4, 6, 2, 181, 756.84, 3, '2025-01-03', 57, 89, 43, 2),
(47, 3, 4, 5, 7, 66, 148.11, 7, '2025-01-19', 57, 89, 44, 1),
(48, 8, 4, 6, 1, 97, 1252.31, 3, '2025-01-11', 57, 89, 45, 1),
(49, 1, 6, 3, 1, 180, 441.29, 4, '2025-05-09', 57, 89, 46, 1),
(50, 3, 2, 2, 5, 199, 256.55, 2, '2025-03-03', 57, 89, 47, 1),
(51, 8, 2, 1, 4, 157, 1268.82, 1, '2025-03-17', 63, 174, 48, 2),
(52, 7, 6, 3, 1, 134, 367.60, 5, '2025-06-06', 13, 27, 49, 2),
(53, 2, 1, 6, 1, 40, 253.06, 3, '2025-06-29', 13, 27, 50, 2),
(54, 7, 4, 1, 6, 160, 1003.73, 4, '2025-06-06', 13, 27, 22, 1),
(55, 3, 5, 1, 3, 168, 166.51, 7, '2025-04-22', 13, 27, 51, 2),
(56, 1, 1, 4, 2, 146, 228.41, 5, '2025-06-07', 13, 27, 25, 1),
(57, 3, 2, 2, 7, 78, 947.80, 1, '2025-05-16', 13, 27, 52, 1),
(58, 8, 5, 2, 1, 61, 1448.57, 2, '2025-01-20', 13, 27, 53, 2),
(59, 2, 5, 6, 7, 140, 475.54, 3, '2025-02-17', 13, 27, 47, 2),
(60, 4, 4, 5, 8, 60, 1462.17, 1, '2025-06-28', 13, 27, 54, 1),
(61, 4, 4, 2, 5, 167, 1017.68, 6, '2025-04-25', 25, 49, 55, 1),
(62, 8, 2, 3, 2, 176, 983.68, 6, '2025-02-11', 13, 27, 56, 1),
(63, 7, 1, 1, 4, 117, 1473.91, 6, '2025-06-06', 13, 27, 57, 2),
(64, 8, 2, 2, 1, 141, 719.50, 6, '2025-05-16', 13, 27, 58, 1),
(65, 1, 5, 5, 6, 72, 1411.90, 6, '2025-03-19', 80, 213, 6, 1),
(66, 2, 2, 3, 8, 50, 344.84, 6, '2025-05-13', 13, 27, 59, 2),
(67, 4, 1, 6, 5, 50, 66.84, 6, '2025-02-19', 34, 54, 19, 1),
(68, 6, 1, 3, 5, 28, 931.16, 6, '2025-03-05', 13, 27, 37, 2),
(69, 8, 6, 6, 2, 114, 888.62, 6, '2025-06-12', 13, 27, 60, 2),
(70, 1, 1, 2, 4, 135, 111.42, 6, '2025-05-11', 13, 27, 61, 2),
(71, 5, 5, 3, 5, 158, 203.55, 6, '2025-03-26', 13, 27, 43, 1),
(72, 2, 2, 2, 5, 64, 94.78, 6, '2025-06-12', 13, 27, 62, 1),
(73, 5, 4, 2, 2, 84, 349.80, 6, '2025-04-08', 25, 49, 47, 2),
(74, 8, 5, 1, 3, 17, 258.12, 6, '2025-01-05', 19, 31, 63, 2),
(75, 3, 5, 3, 4, 142, 219.78, 6, '2025-01-10', 39, 60, 64, 1),
(76, 2, 3, 1, 8, 0, 1374.18, 1, '2025-04-29', 13, 27, 65, 2),
(77, 6, 2, 6, 3, 0, 1377.38, 2, '2025-03-20', 13, 27, 66, 2),
(78, 5, 5, 3, 2, 0, 1278.77, 7, '2025-06-27', 13, 27, 67, 1),
(79, 2, 6, 3, 3, 0, 1095.61, 7, '2025-01-26', 13, 27, 68, 2),
(80, 2, 3, 1, 1, 0, 625.32, 1, '2025-01-17', 13, 27, 2, 1),
(81, 1, 2, 5, 1, 0, 1170.10, 5, '2025-05-24', 13, 27, 69, 1),
(82, 6, 6, 1, 1, 0, 798.63, 6, '2025-04-10', 13, 27, 70, 1),
(83, 3, 6, 1, 1, 0, 484.07, 4, '2025-02-05', 43, 67, 71, 1),
(84, 7, 6, 1, 5, 0, 1010.13, 2, '2025-04-19', 13, 27, 35, 2),
(85, 1, 4, 5, 8, 0, 1427.28, 7, '2025-02-17', 20, 68, 72, 1),
(86, 4, 6, 4, 1, 0, 1432.37, 2, '2025-04-22', 44, 69, 73, 2),
(87, 5, 5, 1, 7, 0, 697.69, 7, '2025-02-06', 13, 27, 74, 2),
(88, 4, 2, 2, 8, 0, 641.18, 5, '2025-01-24', 13, 27, 75, 1),
(89, 8, 2, 4, 6, 0, 1356.63, 5, '2025-05-10', 13, 27, 76, 2),
(90, 8, 2, 2, 5, 0, 498.09, 8, '2025-03-14', 13, 27, 34, 2),
(91, 1, 1, 3, 4, 57, 321.79, 8, '2025-04-15', 13, 27, 77, 1),
(92, 6, 5, 5, 5, 67, 627.40, 5, '2025-01-12', 49, 75, 78, 2),
(93, 6, 6, 2, 8, 120, 1481.95, 2, '2025-03-25', 50, 76, 79, 1),
(94, 7, 6, 2, 3, 45, 916.26, 3, '2025-02-22', 4, 77, 80, 2),
(95, 2, 5, 3, 3, 74, 436.97, 2, '2025-05-18', 77, 215, 81, 2),
(96, 1, 3, 6, 4, 33, 436.68, 6, '2025-05-19', 13, 27, 82, 1),
(97, 7, 2, 3, 6, 107, 932.46, 2, '2025-04-28', 51, 79, 34, 2),
(98, 2, 1, 2, 8, 154, 1456.96, 4, '2025-04-04', 49, 124, 83, 2),
(99, 4, 4, 4, 5, 74, 1065.95, 8, '2025-05-12', 49, 124, 84, 2),
(100, 8, 6, 6, 7, 142, 223.11, 3, '2025-05-06', 53, 82, 85, 1),
(101, 1, 5, 4, 7, 92, 129.74, 7, '2025-02-06', 49, 124, 86, 2),
(102, 4, 1, 5, 3, 141, 1483.40, 6, '2025-02-24', 49, 124, 87, 2),
(103, 6, 6, 3, 5, 70, 922.47, 1, '2025-03-24', 49, 124, 88, 2),
(104, 1, 3, 1, 4, 117, 95.68, 3, '2025-02-09', 13, 27, 89, 2),
(105, 6, 3, 5, 2, 200, 815.81, 8, '2025-01-22', 24, 204, 90, 1),
(106, 2, 3, 4, 7, 91, 213.01, 4, '2025-04-19', 49, 124, 32, 2),
(107, 2, 6, 4, 7, 8, 288.60, 4, '2025-04-06', 32, 172, 91, 1),
(108, 4, 3, 1, 7, 169, 575.16, 4, '2025-05-11', 49, 124, 92, 1),
(109, 7, 6, 5, 7, 115, 1390.65, 5, '2025-06-29', 38, 219, 21, 2),
(110, 2, 1, 3, 7, 146, 120.33, 5, '2025-02-17', 49, 124, 93, 1),
(111, 1, 1, 1, 7, 70, 873.61, 3, '2025-05-18', 49, 124, 47, 2),
(112, 2, 2, 3, 7, 110, 189.74, 4, '2025-04-08', 45, 113, 94, 2),
(113, 4, 6, 5, 7, 69, 784.43, 8, '2025-04-06', 54, 92, 30, 2),
(114, 4, 6, 6, 7, 80, 297.15, 4, '2025-04-07', 49, 124, 19, 1),
(115, 1, 1, 2, 7, 174, 41.32, 4, '2025-04-04', 49, 124, 95, 1),
(116, 1, 4, 5, 7, 4, 909.21, 6, '2025-04-27', 59, 95, 64, 2),
(117, 5, 5, 4, 7, 62, 1062.02, 4, '2025-02-17', 49, 124, 96, 2),
(118, 4, 6, 3, 7, 69, 66.80, 8, '2025-06-29', 18, 136, 43, 1),
(119, 7, 4, 5, 7, 8, 623.28, 5, '2025-03-03', 27, 221, 97, 2),
(120, 4, 3, 3, 7, 137, 1445.26, 8, '2025-06-11', 49, 124, 98, 1),
(121, 2, 6, 4, 7, 189, 1475.29, 6, '2025-03-12', 62, 100, 99, 1),
(122, 5, 2, 6, 7, 92, 21.73, 2, '2025-05-27', 49, 124, 43, 1),
(123, 5, 4, 5, 7, 168, 214.65, 5, '2025-06-06', 49, 124, 100, 2),
(124, 3, 2, 5, 7, 154, 334.59, 8, '2025-06-09', 49, 124, 101, 1),
(125, 8, 2, 6, 7, 129, 1452.09, 4, '2025-02-28', 49, 124, 102, 1),
(126, 2, 6, 5, 2, 126, 159.88, 1, '2025-01-26', 49, 124, 103, 2),
(127, 3, 4, 2, 2, 125, 1326.68, 8, '2025-04-14', 13, 27, 90, 1),
(128, 6, 6, 3, 4, 133, 751.42, 8, '2025-03-16', 69, 132, 104, 2),
(129, 5, 2, 1, 3, 7, 1017.72, 6, '2025-04-07', 69, 132, 105, 2),
(130, 4, 2, 1, 7, 83, 1307.74, 8, '2025-02-22', 64, 187, 106, 2),
(131, 8, 3, 1, 7, 81, 121.39, 7, '2025-02-13', 13, 27, 12, 1),
(132, 7, 4, 2, 1, 61, 922.65, 1, '2025-04-22', 69, 132, 107, 1),
(133, 4, 2, 4, 8, 198, 747.40, 7, '2025-03-15', 69, 132, 108, 1),
(134, 1, 4, 1, 6, 30, 1290.80, 7, '2025-06-01', 17, 111, 109, 2),
(135, 1, 5, 5, 5, 87, 717.62, 8, '2025-03-29', 69, 132, 68, 2),
(136, 7, 2, 3, 5, 20, 1096.14, 3, '2025-05-29', 45, 113, 110, 1),
(137, 5, 3, 2, 8, 63, 495.30, 4, '2025-03-07', 69, 132, 22, 2),
(138, 1, 2, 3, 6, 31, 178.79, 2, '2025-03-13', 69, 132, 111, 1),
(139, 7, 3, 5, 3, 175, 955.48, 6, '2025-05-02', 69, 132, 112, 1),
(140, 6, 5, 2, 2, 107, 1494.94, 7, '2025-06-27', 69, 132, 113, 2),
(141, 4, 5, 4, 7, 165, 275.61, 1, '2025-05-02', 65, 117, 83, 1),
(142, 7, 1, 1, 3, 96, 1247.41, 5, '2025-03-24', 13, 27, 77, 1),
(143, 1, 5, 4, 3, 184, 1190.47, 4, '2025-06-03', 69, 132, 114, 1),
(144, 8, 5, 1, 1, 164, 423.19, 4, '2025-03-13', 70, 119, 115, 2),
(145, 7, 1, 1, 8, 50, 291.48, 3, '2025-01-08', 69, 132, 116, 2),
(146, 8, 2, 2, 5, 159, 1339.97, 7, '2025-02-27', 69, 132, 26, 2),
(147, 4, 3, 1, 6, 44, 1235.32, 2, '2025-01-29', 61, 122, 117, 1),
(148, 2, 6, 1, 1, 105, 1133.50, 6, '2025-04-09', 69, 132, 118, 2),
(149, 8, 2, 3, 4, 55, 1343.62, 1, '2025-01-20', 13, 27, 119, 1),
(150, 6, 4, 4, 7, 34, 1084.99, 8, '2025-02-22', 49, 124, 67, 1),
(151, 1, 1, 2, 7, 130, 268.38, 7, '2025-01-15', 82, 181, 120, 1),
(152, 6, 5, 5, 2, 151, 864.23, 2, '2025-02-27', 13, 27, 121, 2),
(153, 6, 6, 2, 7, 56, 929.73, 3, '2025-04-25', 69, 132, 26, 2),
(154, 4, 2, 1, 6, 99, 94.36, 5, '2025-04-02', 30, 126, 13, 1),
(155, 2, 6, 5, 5, 77, 1213.34, 3, '2025-06-02', 69, 132, 122, 2),
(156, 7, 3, 2, 3, 146, 1159.35, 6, '2025-06-17', 46, 128, 123, 2),
(157, 1, 5, 4, 3, 56, 713.07, 2, '2025-01-20', 69, 132, 124, 2),
(158, 3, 1, 5, 6, 91, 150.08, 2, '2025-02-06', 69, 132, 125, 1),
(159, 7, 3, 3, 7, 79, 1436.96, 6, '2025-02-08', 73, 190, 109, 1),
(160, 2, 5, 4, 3, 82, 312.39, 6, '2025-03-01', 13, 27, 126, 1),
(161, 6, 5, 6, 6, 147, 680.22, 5, '2025-06-04', 13, 27, 127, 2),
(162, 5, 2, 3, 8, 31, 1193.59, 8, '2025-03-02', 69, 132, 98, 1),
(163, 2, 2, 4, 3, 8, 429.17, 4, '2025-04-04', 69, 132, 105, 1),
(164, 5, 1, 2, 1, 151, 1019.12, 8, '2025-04-23', 69, 132, 25, 2),
(165, 7, 3, 4, 5, 102, 160.00, 7, '2025-04-03', 69, 132, 97, 1),
(166, 1, 1, 6, 2, 199, 1359.37, 6, '2025-02-11', 69, 132, 105, 2),
(167, 2, 2, 1, 1, 170, 1344.77, 6, '2025-03-20', 13, 27, 128, 1),
(168, 3, 2, 5, 3, 65, 1377.15, 4, '2025-05-23', 18, 136, 129, 1),
(169, 8, 2, 6, 6, 6, 1486.49, 6, '2025-01-21', 78, 217, 130, 1),
(170, 2, 1, 6, 5, 109, 434.43, 1, '2025-04-14', 13, 27, 131, 2),
(171, 3, 1, 5, 3, 5, 628.01, 1, '2025-04-11', 78, 217, 21, 2),
(172, 4, 4, 1, 7, 191, 1087.24, 7, '2025-05-17', 2, 139, 126, 2),
(173, 6, 3, 4, 2, 105, 572.82, 3, '2025-05-20', 13, 27, 132, 1),
(174, 2, 5, 6, 3, 175, 318.02, 6, '2025-03-07', 78, 217, 133, 2),
(175, 8, 2, 2, 7, 44, 384.86, 8, '2025-05-07', 78, 217, 134, 2),
(176, 7, 1, 1, 2, 127, 104.64, 2, '2025-01-23', 31, 142, 135, 1),
(177, 7, 2, 3, 4, 73, 697.54, 2, '2025-05-29', 21, 143, 136, 2),
(178, 2, 2, 2, 6, 83, 1075.11, 6, '2025-04-03', 78, 217, 113, 1),
(179, 3, 4, 6, 6, 173, 202.45, 2, '2025-04-30', 64, 187, 74, 2),
(180, 7, 2, 1, 5, 75, 231.08, 4, '2025-03-22', 78, 217, 137, 2),
(181, 2, 2, 4, 1, 179, 901.02, 6, '2025-04-25', 78, 217, 11, 1),
(182, 3, 6, 2, 1, 42, 1360.39, 1, '2025-05-30', 78, 217, 138, 1),
(183, 2, 4, 6, 1, 19, 705.42, 3, '2025-06-21', 78, 217, 139, 2),
(184, 1, 4, 5, 8, 40, 792.77, 1, '2025-06-15', 15, 150, 43, 2),
(185, 2, 3, 5, 6, 88, 1317.20, 5, '2025-02-12', 2, 139, 140, 2),
(186, 2, 5, 3, 4, 121, 1360.05, 7, '2025-04-28', 78, 217, 141, 2),
(187, 2, 2, 4, 6, 75, 866.84, 7, '2025-01-05', 78, 217, 120, 1),
(188, 1, 3, 5, 4, 54, 1191.86, 2, '2025-05-08', 8, 15, 109, 1),
(189, 3, 3, 3, 3, 81, 567.97, 4, '2025-01-20', 8, 15, 9, 1),
(190, 1, 1, 3, 5, 131, 1191.62, 5, '2025-04-29', 8, 15, 12, 1),
(191, 3, 5, 4, 6, 13, 1127.63, 8, '2025-03-20', 68, 153, 142, 1),
(192, 5, 4, 5, 5, 73, 187.03, 6, '2025-01-04', 78, 217, 84, 1),
(193, 5, 5, 1, 5, 117, 801.59, 4, '2025-06-21', 78, 217, 143, 2),
(194, 8, 6, 1, 6, 160, 124.85, 5, '2025-06-14', 78, 217, 139, 2),
(195, 6, 1, 4, 4, 162, 111.47, 4, '2025-01-16', 79, 156, 144, 1),
(196, 1, 3, 6, 1, 166, 1051.26, 7, '2025-01-27', 78, 217, 106, 2),
(197, 1, 4, 2, 7, 154, 765.19, 6, '2025-05-02', 78, 217, 145, 2),
(198, 2, 5, 6, 4, 148, 812.27, 8, '2025-06-19', 78, 217, 146, 2),
(199, 8, 4, 5, 4, 165, 1066.49, 1, '2025-06-06', 78, 217, 147, 1),
(200, 2, 5, 1, 8, 114, 163.99, 5, '2025-05-08', 8, 15, 148, 1),
(201, 3, 1, 6, 4, 171, 104.95, 5, '2025-03-07', 81, 161, 149, 1),
(202, 2, 5, 4, 6, 164, 849.43, 2, '2025-02-04', 8, 15, 36, 2),
(203, 6, 2, 6, 6, 34, 521.83, 6, '2025-03-17', 78, 217, 150, 2),
(204, 8, 5, 4, 4, 24, 80.12, 4, '2025-04-04', 22, 163, 151, 2),
(205, 4, 2, 2, 4, 111, 768.38, 4, '2025-01-26', 67, 173, 151, 2),
(206, 2, 6, 1, 7, 78, 963.01, 4, '2025-06-25', 48, 164, 152, 1),
(207, 6, 6, 4, 7, 141, 527.84, 8, '2025-06-05', 78, 217, 153, 1),
(208, 3, 4, 1, 4, 108, 1188.67, 3, '2025-06-25', 37, 166, 154, 2),
(209, 4, 4, 3, 2, 139, 1385.83, 8, '2025-05-03', 78, 217, 133, 2),
(210, 3, 4, 5, 1, 4, 1052.93, 8, '2025-06-12', 78, 217, 126, 1),
(211, 7, 1, 3, 3, 146, 1116.28, 3, '2025-01-12', 78, 217, 136, 1),
(212, 3, 4, 1, 7, 34, 56.72, 7, '2025-05-22', 78, 217, 38, 1),
(213, 6, 5, 3, 1, 150, 968.67, 2, '2025-03-05', 78, 217, 155, 2),
(214, 7, 2, 1, 5, 185, 1386.56, 8, '2025-02-09', 56, 171, 156, 1),
(215, 3, 2, 1, 7, 196, 160.39, 1, '2025-01-10', 32, 172, 157, 2),
(216, 1, 1, 3, 5, 153, 343.80, 1, '2025-03-26', 67, 173, 158, 2),
(217, 1, 6, 4, 2, 109, 579.17, 7, '2025-02-07', 50, 76, 121, 2),
(218, 6, 4, 2, 7, 111, 551.76, 6, '2025-01-03', 63, 174, 28, 2),
(219, 2, 5, 1, 3, 68, 1070.23, 4, '2025-05-02', 40, 175, 146, 1),
(220, 6, 3, 6, 2, 84, 1159.32, 4, '2025-05-15', 78, 217, 159, 1),
(221, 6, 1, 2, 7, 79, 578.95, 1, '2025-05-27', 6, 177, 160, 1),
(222, 2, 3, 6, 2, 115, 778.02, 8, '2025-04-11', 9, 178, 40, 1),
(223, 7, 4, 1, 5, 33, 1389.79, 8, '2025-03-24', 8, 15, 161, 2),
(224, 1, 2, 3, 4, 100, 472.66, 2, '2025-06-20', 72, 205, 121, 1),
(225, 5, 2, 1, 8, 34, 869.03, 4, '2025-05-30', 52, 180, 31, 2),
(226, 6, 5, 1, 7, 62, 1102.16, 6, '2025-01-27', 8, 15, 162, 2),
(227, 8, 2, 4, 7, 79, 1090.60, 4, '2025-05-21', 8, 15, 2, 1),
(228, 3, 5, 2, 3, 144, 1332.99, 2, '2025-06-10', 8, 15, 132, 1),
(229, 3, 3, 1, 5, 33, 904.87, 7, '2025-05-22', 8, 15, 163, 1),
(230, 3, 1, 2, 4, 156, 38.06, 8, '2025-05-02', 82, 181, 66, 1),
(231, 4, 6, 6, 3, 62, 708.90, 5, '2025-03-06', 72, 205, 128, 1),
(232, 5, 1, 3, 2, 56, 1081.79, 5, '2025-06-13', 71, 183, 164, 2),
(233, 6, 1, 2, 6, 137, 695.33, 7, '2025-06-04', 5, 184, 108, 1),
(234, 4, 4, 5, 2, 197, 519.40, 3, '2025-04-26', 72, 205, 165, 1),
(235, 3, 5, 2, 2, 20, 653.05, 2, '2025-02-23', 72, 205, 166, 2),
(236, 2, 1, 3, 3, 183, 321.55, 2, '2025-01-18', 64, 187, 167, 1),
(237, 4, 1, 3, 1, 165, 1429.75, 7, '2025-04-27', 75, 212, 156, 2),
(238, 1, 2, 5, 5, 13, 1129.95, 4, '2025-04-11', 14, 208, 21, 1),
(239, 6, 2, 6, 7, 127, 1293.68, 7, '2025-01-16', 8, 15, 168, 1),
(240, 5, 1, 1, 8, 138, 1455.40, 4, '2025-02-13', 72, 205, 169, 2),
(241, 1, 6, 4, 5, 173, 1479.71, 5, '2025-06-01', 72, 205, 170, 2),
(242, 7, 2, 2, 2, 89, 838.67, 6, '2025-05-08', 8, 15, 114, 1),
(243, 8, 5, 3, 4, 143, 970.25, 2, '2025-03-02', 73, 190, 171, 2),
(244, 4, 4, 1, 8, 158, 1166.79, 2, '2025-01-26', 8, 15, 172, 2),
(245, 2, 6, 2, 2, 89, 412.44, 4, '2025-04-26', 84, 191, 17, 2),
(246, 7, 6, 4, 7, 93, 1376.69, 6, '2025-04-11', 8, 15, 120, 2),
(247, 5, 1, 4, 6, 18, 1064.48, 6, '2025-02-10', 72, 205, 45, 2),
(248, 1, 4, 5, 3, 134, 1144.00, 7, '2025-03-14', 72, 205, 173, 2),
(249, 4, 5, 1, 6, 82, 1016.22, 4, '2025-05-29', 72, 205, 6, 2),
(250, 7, 3, 4, 4, 100, 386.60, 6, '2025-03-27', 8, 15, 174, 2),
(251, 7, 5, 6, 6, 196, 460.71, 7, '2025-04-06', 36, 193, 109, 1),
(252, 8, 6, 5, 6, 162, 1147.23, 2, '2025-01-18', 58, 224, 175, 1),
(253, 6, 3, 6, 2, 149, 597.35, 1, '2025-06-20', 8, 15, 35, 2),
(254, 2, 4, 6, 5, 74, 547.57, 4, '2025-01-14', 72, 205, 176, 1),
(255, 8, 1, 5, 4, 97, 1251.58, 1, '2025-06-19', 8, 15, 173, 2),
(256, 2, 1, 2, 4, 183, 916.41, 6, '2025-04-30', 60, 196, 25, 2),
(257, 4, 6, 4, 2, 200, 335.25, 5, '2025-04-27', 47, 197, 177, 1),
(258, 1, 2, 6, 5, 80, 1273.91, 3, '2025-05-15', 72, 205, 148, 1),
(259, 7, 3, 3, 3, 20, 804.71, 2, '2025-05-13', 55, 198, 103, 2),
(260, 8, 3, 4, 4, 192, 812.58, 1, '2025-03-19', 11, 199, 48, 1),
(261, 5, 6, 5, 1, 177, 1478.62, 2, '2025-05-13', 16, 200, 19, 2),
(262, 6, 2, 6, 6, 145, 480.76, 1, '2025-05-07', 8, 15, 178, 2),
(263, 3, 4, 6, 7, 194, 1196.08, 2, '2025-03-28', 72, 205, 21, 1),
(264, 2, 2, 6, 5, 173, 627.06, 8, '2025-01-29', 10, 202, 179, 2),
(265, 2, 3, 1, 5, 64, 317.57, 6, '2025-03-08', 41, 203, 9, 1),
(266, 2, 2, 2, 5, 151, 535.65, 4, '2025-05-13', 72, 205, 88, 2),
(267, 8, 6, 4, 3, 10, 1045.89, 5, '2025-06-02', 24, 204, 36, 2),
(268, 2, 2, 1, 8, 163, 872.46, 7, '2025-06-29', 1, 4, 180, 2),
(269, 7, 2, 5, 8, 114, 1403.19, 1, '2025-02-02', 72, 205, 178, 1),
(270, 4, 1, 2, 7, 100, 1169.60, 4, '2025-06-29', 76, 206, 181, 1),
(271, 3, 6, 1, 1, 120, 336.71, 1, '2025-06-30', 66, 207, 126, 1),
(272, 3, 1, 6, 5, 63, 1323.66, 4, '2025-06-01', 14, 208, 47, 1),
(273, 3, 5, 5, 8, 167, 1241.02, 8, '2025-04-06', 1, 4, 182, 2),
(274, 4, 3, 6, 7, 19, 1142.91, 5, '2025-03-18', 1, 4, 41, 1),
(275, 3, 2, 2, 1, 142, 1211.60, 4, '2025-01-30', 42, 209, 143, 2),
(276, 8, 1, 5, 3, 196, 760.34, 4, '2025-01-29', 7, 210, 183, 2),
(277, 1, 1, 3, 1, 77, 698.74, 6, '2025-05-08', 74, 211, 7, 2),
(278, 8, 3, 6, 2, 79, 740.55, 6, '2025-04-19', 1, 4, 80, 2),
(279, 7, 6, 2, 3, 173, 1457.87, 4, '2025-03-17', 75, 212, 83, 2),
(280, 4, 2, 6, 5, 106, 1345.86, 7, '2025-03-16', 80, 213, 182, 2),
(281, 7, 2, 4, 6, 173, 719.03, 7, '2025-05-24', 72, 205, 184, 2),
(282, 2, 5, 1, 3, 144, 284.00, 4, '2025-06-05', 1, 4, 155, 1),
(283, 1, 6, 1, 3, 45, 592.47, 3, '2025-06-18', 72, 205, 160, 2),
(284, 7, 6, 1, 5, 119, 487.24, 1, '2025-04-14', 1, 4, 146, 2),
(285, 8, 4, 6, 2, 19, 251.79, 3, '2025-01-06', 1, 4, 81, 1),
(286, 3, 4, 2, 8, 48, 770.70, 3, '2025-05-27', 77, 215, 103, 1),
(287, 5, 6, 4, 5, 117, 1377.15, 4, '2025-01-31', 85, 216, 185, 1),
(288, 7, 2, 6, 5, 171, 286.17, 7, '2025-04-28', 78, 217, 186, 2),
(289, 6, 5, 4, 7, 156, 178.31, 4, '2025-01-29', 28, 218, 187, 1),
(290, 1, 4, 6, 4, 192, 662.27, 8, '2025-05-02', 38, 219, 113, 2),
(291, 3, 6, 6, 2, 4, 1070.88, 8, '2025-05-10', 83, 220, 172, 2),
(292, 6, 4, 3, 4, 112, 98.67, 2, '2025-03-19', 1, 4, 188, 1),
(293, 3, 2, 5, 5, 53, 441.56, 7, '2025-05-16', 72, 205, 189, 2),
(294, 5, 3, 3, 1, 124, 1353.73, 1, '2025-06-09', 27, 221, 190, 2),
(295, 2, 6, 6, 3, 26, 92.10, 2, '2025-05-12', 72, 205, 191, 2),
(296, 3, 5, 3, 6, 179, 1478.86, 5, '2025-01-10', 72, 205, 192, 2),
(297, 1, 6, 2, 8, 35, 22.60, 8, '2025-04-14', 86, 223, 107, 1),
(298, 1, 1, 5, 8, 27, 1123.93, 6, '2025-05-06', 1, 4, 26, 1),
(299, 5, 2, 2, 7, 69, 1295.75, 6, '2025-04-11', 58, 224, 114, 1),
(300, 2, 5, 1, 7, 88, 1481.21, 8, '2025-01-12', 1, 4, 66, 1);


-- --------------------------------------------------------------------
-- 3. CORREÇÕES PÓS-CARGA
-- --------------------------------------------------------------------

-- Corrige registros em que fk_Produto diverge do produto vinculado ao fk_Estoque.
-- No arquivo enviado, existe pelo menos um caso desse tipo. Essa divergência
-- pode gerar números errados no Power BI quando Produto e Estoque forem usados juntos.
UPDATE Registros r
SET fk_Produto = e.fk_Produto
FROM Estoque e
WHERE r.fk_Estoque = e.id_Estoque
  AND r.fk_Produto <> e.fk_Produto;

-- Ajusta todas as sequências SERIAL para evitar erro de chave duplicada
-- em inserções futuras.
SELECT setval(pg_get_serial_sequence('public.cargo', 'id_cargo'), COALESCE((SELECT MAX(id_cargo) FROM cargo), 1), true);
SELECT setval(pg_get_serial_sequence('public.funcionario', 'id_funcionario'), COALESCE((SELECT MAX(id_funcionario) FROM funcionario), 1), true);
SELECT setval(pg_get_serial_sequence('public.corredor', 'id_corredor'), COALESCE((SELECT MAX(id_corredor) FROM corredor), 1), true);
SELECT setval(pg_get_serial_sequence('public.prateleira', 'id_prateleira'), COALESCE((SELECT MAX(id_prateleira) FROM prateleira), 1), true);
SELECT setval(pg_get_serial_sequence('public.prateleira_corredor', 'id_prateleira_corredor'), COALESCE((SELECT MAX(id_prateleira_corredor) FROM prateleira_corredor), 1), true);
SELECT setval(pg_get_serial_sequence('public.cidade', 'id_cidade'), COALESCE((SELECT MAX(id_cidade) FROM cidade), 1), true);
SELECT setval(pg_get_serial_sequence('public.marca', 'id_marca'), COALESCE((SELECT MAX(id_marca) FROM marca), 1), true);
SELECT setval(pg_get_serial_sequence('public.tipo_movimentacao', 'id_tipo_movimentacao'), COALESCE((SELECT MAX(id_tipo_movimentacao) FROM tipo_movimentacao), 1), true);
SELECT setval(pg_get_serial_sequence('public.cliente', 'id_cliente'), COALESCE((SELECT MAX(id_cliente) FROM cliente), 1), true);
SELECT setval(pg_get_serial_sequence('public.categoria', 'id_categoria'), COALESCE((SELECT MAX(id_categoria) FROM categoria), 1), true);
SELECT setval(pg_get_serial_sequence('public.fornecedor', 'id_fornecedor'), COALESCE((SELECT MAX(id_fornecedor) FROM fornecedor), 1), true);
SELECT setval(pg_get_serial_sequence('public.produto', 'id_produto'), COALESCE((SELECT MAX(id_produto) FROM produto), 1), true);
SELECT setval(pg_get_serial_sequence('public.estoque', 'id_estoque'), COALESCE((SELECT MAX(id_estoque) FROM estoque), 1), true);
SELECT setval(pg_get_serial_sequence('public.registros', 'id_registro'), COALESCE((SELECT MAX(id_registro) FROM registros), 1), true);

-- --------------------------------------------------------------------
-- 4. ÍNDICES PARA MELHORAR CONSULTAS E IMPORTAÇÃO NO POWER BI
-- --------------------------------------------------------------------
CREATE INDEX idx_funcionario_fk_cargo ON Funcionario(fk_cargo);
CREATE INDEX idx_prateleira_corredor_fk_prateleira ON Prateleira_Corredor(fk_prateleira);
CREATE INDEX idx_prateleira_corredor_fk_corredor ON Prateleira_Corredor(fk_corredor);
CREATE INDEX idx_fornecedor_fk_cidade ON Fornecedor(fk_cidade);
CREATE INDEX idx_produto_fk_categoria ON Produto(fk_categoria);
CREATE INDEX idx_produto_fk_fornecedor ON Produto(fk_fornecedor);
CREATE INDEX idx_produto_fk_marca ON Produto(fk_marca);
CREATE INDEX idx_produto_cod_produto ON Produto(cod_produto);
CREATE INDEX idx_estoque_fk_produto ON Estoque(fk_produto);
CREATE INDEX idx_registros_data ON Registros(data_movimentacao);
CREATE INDEX idx_registros_fk_cliente ON Registros(fk_cliente);
CREATE INDEX idx_registros_fk_cidade_cliente ON Registros(fk_cidade_cliente);
CREATE INDEX idx_registros_fk_cidade_fornecedor ON Registros(fk_cidade_fornecedor);
CREATE INDEX idx_registros_fk_fornecedor ON Registros(fk_fornecedor);
CREATE INDEX idx_registros_fk_estoque ON Registros(fk_estoque);
CREATE INDEX idx_registros_fk_produto ON Registros(fk_produto);
CREATE INDEX idx_registros_fk_prateleira_corredor ON Registros(fk_prateleira_corredor);
CREATE INDEX idx_registros_fk_tipo_movimentacao ON Registros(fk_tipo_movimentacao);
CREATE INDEX idx_registros_fk_funcionario ON Registros(fk_funcionario);

-- --------------------------------------------------------------------
-- 5. VIEWS PRONTAS PARA O POWER BI
-- Recomendação: no Power BI, carregue principalmente estas views,
-- em vez de carregar todas as tabelas físicas. Isso evita relacionamentos
-- circulares/ambíguos entre Registros, Produto, Estoque, Fornecedor e Cidade.
-- --------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_powerbi_movimentacoes AS
SELECT
    r.id_Registro,
    r.Data_Movimentacao,
    EXTRACT(YEAR FROM r.Data_Movimentacao)::INTEGER AS Ano,
    EXTRACT(MONTH FROM r.Data_Movimentacao)::INTEGER AS Mes_Numero,
    TO_CHAR(r.Data_Movimentacao, 'YYYY-MM') AS Ano_Mes,

    tm.id_Tipo_Movimentacao,
    tm.Tipo_Movimentacao,

    r.Quantidade,
    CASE
        WHEN tm.Tipo_Movimentacao ILIKE 'Sa%' THEN -r.Quantidade
        ELSE r.Quantidade
    END AS Quantidade_Com_Sinal,

    r.valor_unitario,
    (r.Quantidade * r.valor_unitario)::NUMERIC(14,2) AS Valor_Total_Movimentado,

    CASE
        WHEN tm.Tipo_Movimentacao ILIKE 'Sa%' THEN (r.Quantidade * r.valor_unitario)::NUMERIC(14,2)
        ELSE 0::NUMERIC(14,2)
    END AS Faturamento_Saida,

    CASE
        WHEN tm.Tipo_Movimentacao ILIKE 'En%' THEN (r.Quantidade * r.valor_unitario)::NUMERIC(14,2)
        ELSE 0::NUMERIC(14,2)
    END AS Valor_Entrada,

    cli.id_Cliente,
    cli.Nome_Cliente,
    cid_cli.Nome_Cidade AS Cidade_Cliente,
    cid_cli.Nome_Estado AS Estado_Cliente,

    p.id_Produto,
    p.Cod_Produto,
    p.Nome_Produto,
    (p.Cod_Produto || ' - ' || p.Nome_Produto) AS Produto_Rotulo,
    cat.Nome_Categoria,
    m.Nome_Marca,

    f_mov.id_Fornecedor AS id_Fornecedor_Movimentacao,
    f_mov.Nome_Fornecedor AS Fornecedor_Movimentacao,
    cid_f_mov.Nome_Cidade AS Cidade_Fornecedor_Movimentacao,
    cid_f_mov.Nome_Estado AS Estado_Fornecedor_Movimentacao,

    f_prod.id_Fornecedor AS id_Fornecedor_Cadastro_Produto,
    f_prod.Nome_Fornecedor AS Fornecedor_Cadastro_Produto,

    e.id_Estoque,
    e.Estoque_minimo,
    e.Estoque_maximo,
    e.Estoque_atual,
    (e.Estoque_atual - e.Estoque_minimo) AS Saldo_vs_Estoque_Minimo,
    CASE
        WHEN e.Estoque_atual <= e.Estoque_minimo THEN 'Crítico'
        WHEN e.Estoque_atual <= (e.Estoque_minimo * 1.5) THEN 'Atenção'
        ELSE 'OK'
    END AS Status_Estoque,

    fun.id_Funcionario,
    fun.Nome_Funcionario,
    cargo.Nome_Cargo,

    prat.id_Prateleira,
    prat.Nome_Prateleira,
    corr.id_Corredor,
    corr.Nome_Corredor,

    r.Observacoes
FROM Registros r
INNER JOIN Tipo_Movimentacao tm
    ON tm.id_Tipo_Movimentacao = r.fk_Tipo_Movimentacao
INNER JOIN Cliente cli
    ON cli.id_Cliente = r.fk_Cliente
INNER JOIN Cidade cid_cli
    ON cid_cli.id_Cidade = r.fk_Cidade_Cliente
INNER JOIN Cidade cid_f_mov
    ON cid_f_mov.id_Cidade = r.fk_Cidade_Fornecedor
INNER JOIN Fornecedor f_mov
    ON f_mov.id_Fornecedor = r.fk_Fornecedor
INNER JOIN Produto p
    ON p.id_Produto = r.fk_Produto
INNER JOIN Categoria cat
    ON cat.Id_Categoria = p.fk_Categoria
INNER JOIN Marca m
    ON m.id_Marca = p.fk_Marca
INNER JOIN Fornecedor f_prod
    ON f_prod.id_Fornecedor = p.fk_Fornecedor
INNER JOIN Estoque e
    ON e.id_Estoque = r.fk_Estoque
INNER JOIN Funcionario fun
    ON fun.id_Funcionario = r.fk_Funcionario
INNER JOIN Cargo cargo
    ON cargo.id_Cargo = fun.fk_Cargo
INNER JOIN Prateleira_Corredor pc
    ON pc.id_Prateleira_Corredor = r.fk_Prateleira_Corredor
INNER JOIN Prateleira prat
    ON prat.id_Prateleira = pc.fk_Prateleira
INNER JOIN Corredor corr
    ON corr.id_Corredor = pc.fk_Corredor;

CREATE OR REPLACE VIEW vw_powerbi_alerta_estoque AS
WITH movimentacao_produto AS (
    SELECT
        r.fk_Produto,
        SUM(CASE WHEN tm.Tipo_Movimentacao ILIKE 'Sa%' THEN r.Quantidade ELSE 0 END) AS Total_Saidas,
        SUM(CASE WHEN tm.Tipo_Movimentacao ILIKE 'En%' THEN r.Quantidade ELSE 0 END) AS Total_Entradas,
        MAX(CASE WHEN tm.Tipo_Movimentacao ILIKE 'Sa%' THEN r.Data_Movimentacao ELSE NULL END) AS Ultima_Saida,
        MAX(r.Data_Movimentacao) AS Ultima_Movimentacao
    FROM Registros r
    INNER JOIN Tipo_Movimentacao tm
        ON tm.id_Tipo_Movimentacao = r.fk_Tipo_Movimentacao
    GROUP BY r.fk_Produto
),
data_base AS (
    SELECT MAX(Data_Movimentacao) AS Data_Base FROM Registros
)
SELECT
    e.id_Estoque,
    p.id_Produto,
    p.Cod_Produto,
    p.Nome_Produto,
    cat.Nome_Categoria,
    m.Nome_Marca,
    f.Nome_Fornecedor AS Fornecedor_Cadastro_Produto,
    e.Estoque_minimo,
    e.Estoque_maximo,
    e.Estoque_atual,
    (e.Estoque_atual - e.Estoque_minimo) AS Saldo_vs_Estoque_Minimo,
    CASE
        WHEN e.Estoque_atual <= e.Estoque_minimo THEN 'Crítico'
        WHEN e.Estoque_atual <= (e.Estoque_minimo * 1.5) THEN 'Atenção'
        ELSE 'OK'
    END AS Status_Estoque,
    COALESCE(mp.Total_Saidas, 0) AS Total_Saidas,
    COALESCE(mp.Total_Entradas, 0) AS Total_Entradas,
    mp.Ultima_Saida,
    mp.Ultima_Movimentacao,
    CASE
        WHEN mp.Ultima_Saida IS NULL THEN NULL
        ELSE (db.Data_Base - mp.Ultima_Saida)::INTEGER
    END AS Dias_Sem_Saida_No_Periodo
FROM Estoque e
INNER JOIN Produto p
    ON p.id_Produto = e.fk_Produto
INNER JOIN Categoria cat
    ON cat.Id_Categoria = p.fk_Categoria
INNER JOIN Marca m
    ON m.id_Marca = p.fk_Marca
INNER JOIN Fornecedor f
    ON f.id_Fornecedor = p.fk_Fornecedor
LEFT JOIN movimentacao_produto mp
    ON mp.fk_Produto = p.id_Produto
CROSS JOIN data_base db;

CREATE OR REPLACE VIEW vw_powerbi_calendario AS
SELECT
    d::DATE AS Data,
    EXTRACT(YEAR FROM d)::INTEGER AS Ano,
    EXTRACT(MONTH FROM d)::INTEGER AS Mes_Numero,
    TO_CHAR(d, 'TMMonth') AS Mes_Nome,
    TO_CHAR(d, 'YYYY-MM') AS Ano_Mes,
    EXTRACT(QUARTER FROM d)::INTEGER AS Trimestre
FROM generate_series(
    (SELECT MIN(Data_Movimentacao) FROM Registros),
    (SELECT MAX(Data_Movimentacao) FROM Registros),
    INTERVAL '1 day'
) AS calendario(d);

CREATE OR REPLACE VIEW vw_qualidade_dados AS
SELECT 'Total de registros' AS Regra, COUNT(*)::NUMERIC AS Resultado FROM Registros
UNION ALL
SELECT 'Registros com quantidade zero', COUNT(*)::NUMERIC FROM Registros WHERE Quantidade = 0
UNION ALL
SELECT 'Registros com quantidade negativa', COUNT(*)::NUMERIC FROM Registros WHERE Quantidade < 0
UNION ALL
SELECT 'Registros com valor unitário negativo', COUNT(*)::NUMERIC FROM Registros WHERE valor_unitario < 0
UNION ALL
SELECT 'Divergência entre Registros.fk_Produto e Estoque.fk_Produto', COUNT(*)::NUMERIC
FROM Registros r
INNER JOIN Estoque e ON e.id_Estoque = r.fk_Estoque
WHERE r.fk_Produto <> e.fk_Produto
UNION ALL
SELECT 'Códigos de produto repetidos', COUNT(*)::NUMERIC
FROM (
    SELECT Cod_Produto
    FROM Produto
    GROUP BY Cod_Produto
    HAVING COUNT(*) > 1
) s
UNION ALL
SELECT 'Produtos sem registro de estoque', COUNT(*)::NUMERIC
FROM Produto p
LEFT JOIN Estoque e ON e.fk_Produto = p.id_Produto
WHERE e.id_Estoque IS NULL;

ANALYZE;

COMMIT;

-- Consultas rápidas para conferência:
-- SELECT * FROM vw_qualidade_dados;
-- SELECT * FROM vw_powerbi_movimentacoes LIMIT 20;
-- SELECT * FROM vw_powerbi_alerta_estoque ORDER BY Status_Estoque, Saldo_vs_Estoque_Minimo;
