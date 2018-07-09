/******************************************************************************/
/****         Generated by IBExpert 2004.04.01 19.11.2005 17:54:15         ****/
/******************************************************************************/

SET TERM ^ ; 



/******************************************************************************/
/****                          Stored Procedures                           ****/
/******************************************************************************/

CREATE PROCEDURE ADD_BARCODE (
    IMTU INTEGER,
    BARCODE VARCHAR(13),
    ZOOM DOUBLE PRECISION,
    CHANGE INTEGER)
RETURNS (
    RES INTEGER)
AS
BEGIN
  EXIT;
END^


CREATE PROCEDURE ADD_CHANGES (
    IMTU INTEGER)
RETURNS (
    RES INTEGER)
AS
BEGIN
  EXIT;
END^


CREATE PROCEDURE ADD_GOODS (
    IMTU INTEGER,
    CODE INTEGER,
    NAME VARCHAR(30),
    TAXGRP INTEGER,
    ANYPRICE CHAR(1),
    CHCKINT CHAR(1),
    CHCKCNT CHAR(1))
RETURNS (
    RES INTEGER)
AS
BEGIN
  EXIT;
END^


CREATE PROCEDURE ADD_PRICE (
    IMTU INTEGER,
    DEPART INTEGER,
    PRICE DOUBLE PRECISION)
RETURNS (
    RES INTEGER)
AS
BEGIN
  EXIT;
END^


CREATE PROCEDURE CNG_GOODS (
    OCODE INTEGER,
    NCODE INTEGER)
RETURNS (
    RES INTEGER)
AS
BEGIN
  EXIT;
END^


SET TERM ; ^


/******************************************************************************/
/****                          Stored Procedures                           ****/
/******************************************************************************/


SET TERM ^ ;

ALTER PROCEDURE ADD_BARCODE (
    CODE INTEGER,
    BARCODE VARCHAR(13),
    ZOOM DOUBLE PRECISION,
    CHANGE INTEGER)
RETURNS (
    RES INTEGER)
AS
declare variable id_barcode integer;
declare variable id_goods integer;
declare variable goods_id integer;
begin
  res = -1;

  if ((code is null) or (barcode is null)) then
    exit;

  select id from "Goods" where CODE = :code
  into :id_goods;

  select id, goodsid from "BarCodes" where BARCODE = :barcode
  into :id_barcode, :goods_id;

  if (id_barcode is not null) then begin
    if (goods_id <> id_goods) then begin
      if (change = 0) then begin
        res = -2;
        exit;
      end
      else begin
        update "BarCodes" 
        set GOODSID = :id_goods,
            ZOOM = :zoom
        where id = :id_barcode;
        res = 2;
      end
    end
    else begin
      update "BarCodes" 
      set ZOOM = :zoom
      where id = :id_barcode;
      res = 2;
    end
  end
  else begin
    id_barcode = GEN_ID(GEN_BARCODES_ID, 1);

    insert into "BarCodes" values (:id_barcode, :id_goods, :barcode, :zoom);
    res = 1;
  end
  
end
^

ALTER PROCEDURE ADD_CHANGES (
    CODE INTEGER)
RETURNS (
    RES INTEGER)
AS
declare variable id_goods integer;
declare variable id_changes integer;
begin

    res = -1;

    if (code is null) then
        exit;

    select id from "Goods" where CODE = :code
    into :id_goods;

    if (id_goods is null) then 
        exit;

    id_changes = GEN_ID(GEN_GOODSCHANGES_ID, 1);

    insert into "GoodsChanges" values (:id_changes,:id_goods,1,'localhost');

    res = 1;

end
^

ALTER PROCEDURE ADD_GOODS (
    CODE INTEGER,
    NAME VARCHAR(30),
    TAXGRP INTEGER,
    ANYPRICE CHAR(1),
    CHCKINT CHAR(1),
    CHCKCNT CHAR(1))
RETURNS (
    RES INTEGER)
AS
declare variable id_goods integer;
declare variable id_EcrRef integer;
declare variable MaxEcrLine integer;

begin

    res = -1;

    if ((code is null) or (name is null)) then
        exit;
    if (anyprice is null) then anyprice = 'f';
    if (chckint is null) then chckint = 'f';
    if (chckcnt is null) then chckcnt = 'f';

    select id from "Goods" where CODE = :code
    into :id_goods;

    if (id_goods is not null) then begin
        if (taxgrp > 0) then begin

            update "Goods"
            set
                NAME = :name,
                ECRNAME = :name,
                TAXID = :taxgrp, 
                CHKINTEGER = :chckint,
                ANYPRICE = :anyprice,
                CHKCOUNT = :chckcnt
            where id = :id_goods;

        end
        else begin

            update "Goods"
            set
                NAME = :name,
                ECRNAME = :name,
                CHKINTEGER = :chckint,
                ANYPRICE = :anyprice,
                CHKCOUNT = :chckcnt
            where id = :id_goods;

        end

        res = 1;

    end
    else begin

        if (taxgrp < 0) then taxgrp = 2;

        id_goods = GEN_ID(GEN_GOODS_ID, 1);

        insert into "Goods" (ID,CODE,NAME,ECRNAME,TAXID,GOODSGRPID,
                            DISABLED,CHKINTEGER,ANYPRICE,CHKCOUNT)
        values (:id_goods,:code,:name,:name,:taxgrp,1,'F',:chckint,:anyprice,:chckcnt);

        res = 1;

    end

end
^

ALTER PROCEDURE ADD_PRICE (
    CODE INTEGER,
    DEPART INTEGER,
    PRICE DOUBLE PRECISION)
RETURNS (
    RES INTEGER)
AS
declare variable id_goods integer;
declare variable id_depart integer;
declare variable id_prices integer;
begin

    res = -1;

    if ((code is null) or (depart is null) or (price is null)) then
        exit;

    select id from "Goods" where CODE = :code
    into :id_goods;

    if (id_goods is null) then 
        exit;

    select id from "Departs" where NUMBER = :depart
    into :id_depart;

    if (id_depart is null) then 
        exit;

    select id from "DepPrice" 
    where DEPARTID = :id_depart and GOODSID = :id_goods
    into :id_prices;

    if (id_prices is not null) then begin
        
        update "DepPrice" 
        set PRICE = :price
        where id = :id_prices;

    end
    else begin

        id_prices = GEN_ID(GEN_DEPPRICE_ID, 1);

        insert into "DepPrice" values (:id_prices,:id_depart,:id_goods,0,:price,:id_depart);

    end

    res = 1;

end
^

ALTER PROCEDURE CNG_GOODS (
    OCODE INTEGER,
    NCODE INTEGER)
RETURNS (RES INTEGER)
AS
begin

    res = -1;

    if ((ocode is null) or (ncode is null)) then
        exit;

    update "EcrSells" set ecrcode = :ncode where ecrcode = :ocode;

    update "Goods" set code = :ncode where code = :ocode;

		res = 1;

end
^

SET TERM ; ^
