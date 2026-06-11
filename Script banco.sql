create database projeto_integrador;
use projeto_integrador;

create table Cargo(
    id_Cargo int primary key auto_increment,
    Nome_Cargo varchar(255) not null,
    observacoes varchar(255)
);

create table Funcionario(
    id_Funcionario int primary key auto_increment,
    Nome_Funcionario varchar(255) not null,
    fk_cargo int not null,
    constraint cs_Funcionario_Cargo
        foreign key (fk_cargo) references Cargo(id_Cargo) 
        on delete cascade on update cascade
);

create table Corredor(
    id_Corredor int primary key auto_increment,
    Nome_Corredor varchar(255) not null,
    observacoes varchar(255)
);

create table Prateleira(
    id_Prateleira int primary key auto_increment,
    Nome_Prateleira varchar(255) not null,
    observacoes varchar(255)
);

create table Prateleira_Corredor( 
    Id_Prateleria_Corredor int primary key auto_increment,
    fk_Prateleira int not null,
    fk_Corredor int not null,
    constraint cs_Prateleira_Prateleira_Corredor
        foreign key (fk_Prateleira) references Prateleira(id_Prateleira)
        on delete cascade on update cascade,
    constraint cs_Prateleira_Corredor_Corredor
        foreign key (fk_Corredor) references Corredor(id_Corredor) 
        on delete cascade on update cascade
);

create table Cidade(
    id_Cidade int primary key auto_increment,
    Nome_Estado varchar(50) not null,
    Nome_Cidade varchar(100) not null,
    Nome_Pais varchar(50) not null,
    observacoes varchar(255)
);

-- 7. Marca (Independente)
create table Marca(
    id_Marca int primary key auto_increment,
    Nome_Marca varchar(255) not null,
    observacoes varchar(255)    
);


create table Tipo_Movimentacao(
    id_Tipo_Movimentacao int primary key auto_increment,
    Tipo_Movimentacao varchar(255) not null,
    observacoes varchar(255)
);


create table Cliente(
    id_Cliente int primary key auto_increment, 
    Nome_Cliente varchar(255) not null,       
    fk_Cidade int not null,
    observacoes varchar(255),
    constraint fk_Cidade_Cliente
        foreign key(fk_Cidade) references Cidade(id_Cidade)
        on update cascade on delete cascade
);


create table Categoria(
    Id_Categoria int primary key auto_increment,
    Nome_Categoria varchar(255) not null,
    observacoes varchar(255)
);
    

create table Fornecedor(
    Id_Fornecedor int primary key auto_increment,
    Nome_Fornecedor varchar(255) not null,
    fk_Cidade int not null,
    observacoes varchar(255),
    constraint fk_Fornecedor_Cidade
        foreign key (fk_Cidade) references Cidade (id_Cidade)
        on delete cascade on update cascade
);


create table Produto(
    id_Produto int primary key auto_increment,
    Cod_Produto varchar(20) not null,
    Nome_Produto varchar(255) not null,
    fk_Categoria int not null,   
    fk_Fornecedor int not null,  
    fk_Marca int not null,
    
    constraint fk_Produto_Categoria 
        foreign key (fk_Categoria) references Categoria (Id_Categoria)
        on delete cascade on update cascade,
    constraint fk_Produto_Fornecedor
        foreign key (fk_Fornecedor) references Fornecedor (Id_Fornecedor)
        on delete cascade on update cascade,
    constraint fk_Produto_Marca
        foreign key (fk_Marca) references Marca (id_Marca)
        on delete cascade on update cascade
);


create table Estoque(
    id_Estoque int primary key auto_increment,
    Estoque_minimo int not null,
    Estoque_maximo int not null,
    Estoque_atual int not null,
    fk_Prateleira_corredor int not null,
    fk_Produto int not null,
    Observacoes varchar(255),
    
    constraint fk_Estoque_Prateleiras_corredores
        foreign key (fk_Prateleira_corredor) references Prateleira_Corredor (Id_Prateleria_Corredor)
        on delete cascade on update cascade,
    constraint fk_Estoque_Produto
        foreign key (fk_Produto) references Produto (id_Produto)
        on delete cascade on update cascade
);
    

create table Registros(
    id_Registro int primary key auto_increment,
    fk_Cliente int not null,
    Quantidade int not null,
    Data_Movimentacao date not null,
    valor_unitario decimal(10,2) not null,
    fk_Estoque int not null,
    Observacoes varchar(255),
    fk_Produto int not null,
    
    constraint fk_Registros_Cliente
        foreign key (fk_Cliente) references Cliente (id_Cliente)
        on delete cascade on update cascade,
    constraint fk_Registros_Estoque
        foreign key (fk_Estoque) references Estoque (id_Estoque) 
        on delete cascade on update cascade,  
    constraint fk_Registros_Produto
        foreign key (fk_Produto) references Produto (id_Produto)
        on delete cascade on update cascade  
);

show tables;