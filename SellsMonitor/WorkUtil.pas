unit WorkUtil;

interface

uses
  Windows, Messages, Classes, Graphics, Controls, Forms, Dialogs,
  IBSQL, IBDatabase, vIBDB,
  db, dbclient, vIBProvide, IBQuery, IBCustomDataSet, vStdCtrl,
  StdCtrls, ComCtrls, Grids, DBGrids, RXDBCtrl, ExtCtrls, Placemnt, RXSplit,
  vDB, Menus, RxMenus, ActnList;

const
  __NoInfo      = '���������� �����������';
  __DiffFName   = '����������� �� �����';
  __SoldFName   = '��������� �����';
  __AnnulFName  = '�������������� ����';
  __ChecksFName = '����';
                   
  __DATE_BEGIN  = '%DATE_BEGIN%';
  __DATE_END    = '%DATE_END%';
  __ECRPAY      = '%ECRPAYID%';
  __SALESID     = '%SALESID%';
  __GOODSID     = '%GOODSID%';
  
  __Annul_SQL =   'select '+
              'b.SerNumber as SerNumber, '+
              'b.moment as moment, '+
              'b.chknumber as chknumber, '+
              'a.EcrPayID as EcrPayID, '+
              'IIF(b.paycash is not null,''cash'',''credit'') as paytype, '+
              'Sum(a.Total) as TotalSTR, '+
              'Sum(b.Total)/Count(b.ID) as TotalCHK '+
            'from "EcrSells" a, "EcrPays" b '+
            'where a.EcrPayID=b.ID and '+
              '(a.Moment >= ''%DATE_BEGIN%'') and (a.Moment < ''%DATE_END%'') '+
            'group by  '+
              'b.SerNumber, b.moment, b.chknumber, a.EcrPayID, '+
              'IIF(b.paycash is not null,''cash'',''credit'') '+
            'having ((Sum(a.Total) - Sum(b.Total)/Count(b.ID))>0.009 or '+
                   '(Sum(b.Total)/Count(b.ID) - Sum(a.Total))>0.009) and '+
                   '(Sum(b.Total)/Count(b.ID) = 0) '+
            'order by 2';

  __Annul_SQL_Detail ='select '+
                  'a.SerNumber as SerNumber, '+
                  'a.moment as moment, '+
                  'a.chknumber as chknumber, '+
                  'b.code as code, '+
                  'b.name as name, '+
                  'a.price as price, '+
                  'a.quantity as quantity, '+
                  'a.summa as summa, '+
                  '(a.addition - a.discount) as discount, '+
                  'a.total as total '+
                'from "EcrSells" a '+
                'left join "Goods" b on a.GoodsId = b.Id '+
                'where a.EcrPayID= %ECRPAYID%';
                   
  __Diff_SQL =   'select '+
              'b.SerNumber as SerNumber, '+
              'b.moment as moment, '+
              'b.chknumber as chknumber, '+
              'a.EcrPayID as EcrPayID, '+
              'IIF(b.paycash is not null,''cash'',''credit'') as paytype, '+
              'Sum(a.Total) as TotalSTR, '+
              'Sum(b.Total)/Count(b.ID) as TotalCHK, '+
              'Sum(b.Total)/Count(b.ID) - Sum(a.Total) as TotalDiff '+
            'from "EcrSells" a, "EcrPays" b '+
            'where a.EcrPayID=b.ID and '+
              '(a.Moment >= ''%DATE_BEGIN%'') and (a.Moment < ''%DATE_END%'') '+
            'group by  '+
              'b.SerNumber, b.moment, b.chknumber, a.EcrPayID, '+
              'IIF(b.paycash is not null,''cash'',''credit'') '+
            'having ((Sum(a.Total) - Sum(b.Total)/Count(b.ID))>0.009 or '+
                   '(Sum(b.Total)/Count(b.ID) - Sum(a.Total))>0.009) and '+
                   '(Sum(b.Total)/Count(b.ID) <> 0) '+
            'union all '+
            'select '+
              'b.SerNumber as SerNumber, '+
              'b.moment as moment, '+
              'b.chknumber as chknumber, '+
              'null, '+
              'IIF(b.paycash is not null,''cash'',''credit'') as paytype, '+
              '0, '+
              'Sum(b.Total)/Count(b.ID) as TotalCHK, '+
              'Sum(b.Total)/Count(b.ID) as TotalDiff '+
            'from "EcrPays" b '+
            'where (b.Moment >= ''%DATE_BEGIN%'') and (b.Moment < ''%DATE_END%'') and '+
                    'not exists(select * from "EcrSells" a where a.EcrPayID=b.ID) '+
            'group by '+
              'b.SerNumber, b.moment, b.chknumber, null, '+
              'IIF(b.paycash is not null,''cash'',''credit'') '+
            'order by 2';

  __Diff_SQL_Detail ='select '+
                  'a.ID as ID, '+
                  'a.SerNumber as SerNumber, '+
                  'a.moment as moment, '+
                  'a.chknumber as chknumber, '+
                  'b.code as code, '+
                  'b.name as name, '+
                  'a.price as price, '+
                  'a.quantity as quantity, '+
                  'a.summa as summa, '+
                  '(a.addition - a.discount) as discount, '+
                  'a.total as total '+
                'from "EcrSells" a '+
                'left join "Goods" b on a.GoodsId = b.Id '+
                'where a.EcrPayID= %ECRPAYID% '+
                'order by 3';
                   
  __Diff_SQL_DelDiff = 'delete '+
                  'from "EcrSells" '+
                  'where ID = %SALESID%';
                
  __SoldG_SQL =   'select '+
              'b.SerNumber as SerNumber, '+
              'b.moment as moment, '+
              'b.chknumber as chknumber, '+
              'a.EcrPayID as EcrPayID, '+
              'IIF(b.paycash is not null,''cash'',''credit'') as paytype, '+
              'Sum(b.Total)/Count(b.ID) as TotalCHK '+
            'from "EcrSells" a, "EcrPays" b '+
            'where a.EcrPayID=b.ID and '+
              '(a.Moment >= ''%DATE_BEGIN%'') and (a.Moment < ''%DATE_END%'') and '+
              'a.GoodsID = %GOODSID% '+
            'group by  '+
              'b.SerNumber, b.moment, b.chknumber, a.EcrPayID, '+
              'IIF(b.paycash is not null,''cash'',''credit'') '+
            'order by 2';

  __SoldG_SQL_Detail ='select '+
                  'a.ID as ID, '+
                  'a.SerNumber as SerNumber, '+
                  'a.moment as moment, '+
                  'a.chknumber as chknumber, '+
                  'b.code as code, '+
                  'b.name as name, '+
                  'a.price as price, '+
                  'a.quantity as quantity, '+
                  'a.summa as summa, '+
                  '(a.addition - a.discount) as discount, '+
                  'a.total as total '+
                'from "EcrSells" a '+
                'left join "Goods" b on a.GoodsId = b.Id '+
                'where a.EcrPayID= %ECRPAYID% '+
                'order by 3';
                   
  __Checks_SQL =   'select '+
              'b.moment as moment, '+
              'b.SerNumber as SerNumber, '+
              'b.chknumber as chknumber, '+
              'a.EcrPayID as EcrPayID, '+
              'IIF(b.paycash is not null,''cash'',''credit'') as paytype, '+
              'Sum(b.Total)/Count(b.ID) as TotalCHK '+
            'from "EcrSells" a, "EcrPays" b '+
            'where a.EcrPayID=b.ID and '+
              '(a.Moment >= ''%DATE_BEGIN%'') and (a.Moment < ''%DATE_END%'') '+
            'group by  '+
              'b.moment, b.SerNumber, b.chknumber, a.EcrPayID, '+
              'IIF(b.paycash is not null,''cash'',''credit'') '+
            'order by 1';

  __Checks_SQL_Detail ='select '+
                  'a.ID as ID, '+
                  'a.SerNumber as SerNumber, '+
                  'a.moment as moment, '+
                  'a.chknumber as chknumber, '+
                  'b.code as code, '+
                  'b.name as name, '+
                  'a.price as price, '+
                  'a.quantity as quantity, '+
                  'a.summa as summa, '+
                  '(a.addition - a.discount) as discount, '+
                  'a.total as total '+
                'from "EcrSells" a '+
                'left join "Goods" b on a.GoodsId = b.Id '+
                'where a.EcrPayID= %ECRPAYID% '+
                'order by 3';
                
  __Sold_SQL =  'Select g.Id as GoodsID, g.Code as Code, g.Name as Name, sum(a.Quantity) as Quantity'+
                ' from "EcrSells" a'+
                ' left join "EcrPays" b on (b.id=a.EcrPayID)'+
                ' left join "Goods" g on (a.goodsid=g.id)'+
                ' where ((a.moment >= ''%DATE_BEGIN%'') and (a.moment < ''%DATE_END%'')) and'+
                '       (((b.oper in (1,2)) and (b.total = 0)) or'+
                '        ((b.oper in (5,10,11)) and (b.chknumber <> a.chknumber)) or'+
                '        ((b.oper in (1,2)) and (b.total <> 0)))'+
                ' Group by g.Id, g.Code, g.Name'+
                ' having sum(a.Quantity) <> 0'+
                ' Order by 2';
            
  __ID        = 'ID';
  __SerNumber = 'SerNumber';      __fnSerNumber = '�����';                   
  __Moment    = 'moment';         __fnMoment    = '����� ��������';
  __Chknumber = 'chknumber';      __fnChknumber = '����� ����';
  __EcrPayID  = 'EcrPayID';
  __Paytype   = 'paytype';        __fnPaytype   = '������';
  __TotalSTR  = 'TotalSTR';       __fnTotalSTR  = '����� �� �������';
  __TotalCHK  = 'TotalCHK';       __fnTotalCHK  = '����� �� ����';
  __TotalDiff = 'TotalDiff';      __fnTotalDiff = '�������';
  __Code      = 'code';           __fnCode      = '��� ������';
  __Name      = 'name';           __fnName      = '������������';
  __Price     = 'Price';          __fnPrice     = '����';
  __Quantity  = 'Quantity';       __fnQuantity  = '����������';
  __Summa     = 'Summa';          __fnSumma     = '�����';
  __Discount  = 'Discount';       __fnDiscount  = '������';
  __Total     = 'Total';          __fnTotal     = '�����';
  __GID       = 'GoodsID';

  __PathDelimiter                 = '\';
  __DiffSQLFile                   = 'Diff.sql';
  __DiffDetailSQLFile             = 'Diffdetail.sql';
  __DelDiffSQLFile                = 'DelDiff.sql';
  __AnnulSQLFile                  = 'Annul.sql';
  __AnnulDetailSQLFile            = 'Annuldetail.sql';
  __DelWorkSQLFile                = 'DelWork.sql';
  __SoldDetailSQLFile             = 'SoldDetail.sql';
  __SoldGDetailDetailSQLFile      = 'SoldDetaildetail.sql';
  __DelWorkDetailSQLFile          = 'DelWorkDetail.sql';
  __SoldGoodsSQLFile              = 'SoldGoods.sql';
  __ChecksSQLFile                 = 'Checks.sql';
  __ChecksGoodsSQLFile            = 'ChecksGoods.sql';
  

  resSaleCode       = '������ �� ����'; 
  resSaleBar        = '������ �� �����-����';
  resSaleArt        = '������� �� ��������';
  resDiscount       = '������';
  resPayment        = '������';
  resInOut          = '��������/������';
  resNullCheck      = '������� ���';
  resPrtPayment     = '��������� ������';
  resQueryKey       = '������ �� �����';
  resQeryDisc       = '������ ������';
  resAnnul          = '������������� ����';
  resRejectAnnul    = '������ �������������';
  resError          = '������ ��������';
  resNoGoodsParam   = '����� �� ������';
  
  
type
  TSysKeyDown = procedure(var Message: TWMKeyDown);
  
  TWorkForm = class(TForm)
    vPWork: TvPanel;
    vPParams: TvPanel;
    vPGrid: TvPanel;
    dgWork: TRxDBGrid;
    dtpBegin: TDateTimePicker;
    Label1: TLabel;
    Label2: TLabel;
    dtpEnd: TDateTimePicker;
    bGo: TButton;
    StatusBar1: TStatusBar;
    RxSplitter1: TRxSplitter;
    vPWorkDetail: TvPanel;
    dgWorkDetail: TRxDBGrid;
    vPGoods: TvPanel;
    vPDetailGrid: TvPanel;
    dsWork: TvDataSource;
    dsWorkDetail: TvDataSource;
    alFilter: TActionList;
    Filter: TAction;
    fsWork: TFormStorage;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bSoldGGoClick(Sender: TObject);
    procedure bAnnulGoClick(Sender: TObject);
    procedure bSoldGoClick(Sender: TObject);
    procedure bDiffGoClick(Sender: TObject);
    procedure bChecksGoClick(Sender: TObject);
    procedure dtpBeginChange(Sender: TObject);
    procedure dtpEndChange(Sender: TObject);
    procedure dgWorkDblClick(Sender: TObject);
    procedure dgWorkKeyPress(Sender: TObject; var Key: Char);
    procedure dgSoldDblClick(Sender: TObject);
    procedure dgSoldKeyPress(Sender: TObject; var Key: Char);
    procedure dgWorkGetCellParams(Sender: TObject; Field: TField;
      AFont: TFont; var Background: TColor; Highlight: Boolean);
    procedure dgWorkGetCellParamsForChecks(Sender: TObject; Field: TField;
      AFont: TFont; var Background: TColor; Highlight: Boolean);
    procedure SoldFilterExecute(Sender: TObject);
    procedure ChecksFilterExecute(Sender: TObject);
{$ifdef UpdateDB}
    procedure UpdateDB;
{$endif}
  private
    { Private declarations }
    __DataModified: Boolean;
    __DB_FileName: String;
    __DB_user: String;
    __DB_pass: String;    
    __ProtocolDir: String;
    __cdsWork: TClientDataSet;
    __cdsWorkDetail: TClientDataSet;
    FOnSysKeyDown: TSysKeyDown;

    function __GetParams: Boolean;
    procedure __cdsAfterOpen(_DataSet: TDataSet);
    procedure __SelectData(var _cds: TClientDataSet; _SQL: String);
    procedure __DeleteData(_SQL: String);
    procedure __GetDiff(var _cds: TClientDataSet);
    procedure __DelDiff(id: Integer);
    procedure __GetAnnul(var _cds: TClientDataSet);
    procedure __GetSoldG(var _cds: TClientDataSet);
    procedure __GetSold(var _cds: TClientDataSet);
    procedure __GetSoldGDetailDetail(var _cds: TClientDataSet);
    procedure __GetDiffDetail(var _cds: TClientDataSet);
    procedure __GetAnnulDetail(var _cds: TClientDataSet);
    procedure __GetChecks(var _cds: TClientDataSet);
    procedure __GetChecksDetail(var _cds: TClientDataSet);
    procedure __AfterSoldGScroll(DataSet: TDataSet);
    procedure __AfterAnnulScroll(DataSet: TDataSet);
    procedure __AfterDiffScroll(DataSet: TDataSet);
    procedure __AfterChecksScroll(DataSet: TDataSet);
    procedure __DetailBeforeDiffDelete(DataSet: TDataSet);
    procedure __DetailAfterDiffDelete(DataSet: TDataSet);
    function __FindProtocolFile(_Dir, _SN: String; _Date: TDateTime; var _Fn: String): Boolean;
    procedure __ParseProtocol_Show(var _Stream: TStrings);
  public
    { Public declarations }
    __GoodsIdDetail: Integer;
  end;

implementation

uses
  Const_Type, DateUtil, StrUtils, SysUtils, StrFunc, 
  ListProtocol, Progress, 
{$ifdef UpdateDB}
  UpdateDB, 
{$endif}
  WaitForm;  

{$R *.DFM}

function TWorkForm.__GetParams: Boolean;
var
  _RegIniFileName: String;
  _K:              DWORD;
  _TempStr:        String;
  _Def__Protocol,
  _Def__TmpDir:   String;
  
begin
  Result := True;
  try
    _RegIniFileName := Copy(ParamStr(0), 1, LastDelimiter(PathDelimiter, ParamStr(0))) + RegIniFileNameC;

    SetLength(_TempStr, LenIniStr);
    FillChar(Pointer(_TempStr)^, LenIniStr, $0);
    _K:=GetPrivateProfileString(PChar(SectionCommon), PChar(DBK),
                              PChar(Def_DB_FileName), PChar(_TempStr), LenIniStr,
                              PChar(_RegIniFileName));
    __DB_FileName := Trim(_TempStr);
    if (__DB_FileName = '')or(not BOOL(_K)) then __DB_FileName := Def_DB_FileName;

    SetLength(_TempStr, LenIniStr);
    FillChar(Pointer(_TempStr)^, LenIniStr, $0);
    _K:=GetPrivateProfileString(PChar(SectionCommon), PChar(DBUserK),
                              PChar(Def_DB_user), PChar(_TempStr), LenIniStr,
                              PChar(_RegIniFileName));
    __DB_user := Trim(_TempStr);
    if (__DB_user = '')or(not BOOL(_K)) then __DB_user := Def_DB_user;

    SetLength(_TempStr, LenIniStr);
    FillChar(Pointer(_TempStr)^, LenIniStr, $0);
    _K:=GetPrivateProfileString(PChar(SectionCommon), PChar(DBPassK),
                              PChar(Def_DB_pass), PChar(_TempStr), LenIniStr,
                              PChar(_RegIniFileName));
    __DB_pass := Trim(_TempStr);
    if (__DB_pass = '')or(not BOOL(_K)) then __DB_pass := Def_DB_pass;

    _Def__TmpDir := Copy(ParamStr(0), 1, LastDelimiter(PathDelimiter, ParamStr(0)));
    if (LastDelimiter(PathDelimiter, _Def__TmpDir) <> Length(_Def__TmpDir)) then
      _Def__TmpDir := _Def__TmpDir + PathDelimiter;
    _Def__Protocol := _Def__TmpDir + 'Protocol';

    SetLength(_TempStr, LenIniStr);
    FillChar(Pointer(_TempStr)^, LenIniStr, $0);
    _K:=GetPrivateProfileString(PChar(SectionLibrary), PChar(ProtocolDirK),
                              PChar(_Def__Protocol), PChar(_TempStr), LenIniStr,
                              PChar(_RegIniFileName));
    __ProtocolDir := Trim(_TempStr);
    if (__ProtocolDir = '')or(not BOOL(_K)) then __ProtocolDir := _Def__Protocol;
    if (LastDelimiter(PathDelimiter, __ProtocolDir) <> Length(__ProtocolDir)) then
      __ProtocolDir := __ProtocolDir + PathDelimiter;
  except
    Result := False;
  end;
end;

procedure TWorkForm.__cdsAfterOpen(_DataSet: TDataSet);
begin
  TClientDataSet(_DataSet).LogChanges:=False;
end;

procedure TWorkForm.__SelectData(var _cds: TClientDataSet; _SQL: String);
var
  _DB: TvIBDataBase;
  _T: TvIBTransaction;
  _Q: TvIBDataSet;
  _P: TvIBDataSetProvider;
begin
  _T := TvIBTransaction.Create(nil);
  _DB := TvIBDataBase.Create(nil);
  try
    With _DB do begin
      DatabaseName := __DB_FileName;
      Params.Clear;
      Params.Append('user_name=' + __DB_user);
      Params.Append('password=' + __DB_pass);
      Params.Append('lc_ctype=WIN1251');
      LoginPrompt := False;
      SQLDialect := 3;
      TraceFlags := [];
    end;
    if not _DB.Connected then
      _DB.Open;                  
    with _T do begin
      Params.Clear;
      Params.Append('read_committed');
      Params.Append('rec_version');
      Params.Append('nowait');
      DefaultDatabase := _DB;
      DefaultAction := taCommit;
    end;
    _Q := TvIBDataSet.Create(nil);
    _Q.Database := _DB;
    _Q.Transaction := _T;
    _Q.BufferChunks := 10000;
    _Q.CachedUpdates := False;
    _Q.RequestLive := False;

    _Q.SQL.Clear;
    _Q.SQL.Append(_SQL);

    _cds := TClientDataSet.Create(nil);
    _cds.AfterOpen := __cdsAfterOpen;
    _P := TvIBDataSetProvider.Create(nil);
    _P.DataSet := _Q;
    _T.StartTransaction;
    try
      _Q.Prepare;
      _Q.Open;
      _Q.First;
    
      _cds.Data := _P.Data;
      _T.Commit;
    except
      on E: Exception do begin
        _T.RollBack;
        _P.Free;
        _Q.Free;
        ShowMessage(E.Message);
      end;
    end;
    _P.Free;
    _Q.Free;
  finally
    if ( assigned( _DB ) ) then FreeandNil( _DB );
    if ( assigned( _T ) ) then FreeandNil( _T );
  end;
end;

procedure TWorkForm.__DeleteData(_SQL: String);
var
  _DB: TvIBDataBase;
  _T: TvIBTransaction;
  _Q: TIBSQL;
begin
  _T := TvIBTransaction.Create(nil);
  _DB := TvIBDataBase.Create(nil);
  try
    With _DB do begin
      DatabaseName := __DB_FileName;
      Params.Clear;
      Params.Append('user_name=' + __DB_user);
      Params.Append('password=' + __DB_pass);
      Params.Append('lc_ctype=WIN1251');
      LoginPrompt := False;
      SQLDialect := 3;
      TraceFlags := [];
    end;
    if not _DB.Connected then
      _DB.Open;                  
    with _T do begin
      Params.Clear;
      Params.Append('read_committed');
      Params.Append('rec_version');
      Params.Append('nowait');
      DefaultDatabase := _DB;
      DefaultAction := taCommit;
    end;
    _Q := TIBSQL.Create(nil);
    _Q.Database := _DB;
    _Q.Transaction := _T;
    _Q.SQL.Clear;
    _Q.SQL.Append(_SQL);
    _T.StartTransaction;
    try
      _Q.ExecQuery;
      _T.Commit;
    except
      on E: Exception do begin
        _T.RollBack;
        _Q.Free;
        ShowMessage(E.Message);
      end;
    end;
    _Q.Free;
  finally
    if ( assigned( _DB ) ) then FreeandNil( _DB );
    if ( assigned( _T ) ) then FreeandNil( _T );
  end;
end;

procedure TWorkForm.__GetDiff(var _cds: TClientDataSet);
var
  _SQL: TStrings;
begin
  if __GetParams then begin
    _SQL := TStringList.Create;
    if FileExists(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__DiffSQLFile) then begin
      _SQL.LoadFromFile(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__DiffSQLFile)
    end      
    else 
      _SQL.Text := __Diff_SQL;
    _SQL.Text := ReplaceStr(_SQL.Text, __DATE_BEGIN, DateToStr(dtpBegin.Date));
    _SQL.Text := ReplaceStr(_SQL.Text, __DATE_END, DateToStr(dtpEnd.Date));
    __SelectData( _cds, _SQL.Text );
    FreeAndNil(_SQL);
    _cds.First;
  end;
end;

procedure TWorkForm.__GetDiffDetail(var _cds: TClientDataSet);
var
  _SQL: TStrings;
begin
  if __GetParams then begin
    _SQL := TStringList.Create;
    if FileExists(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__DiffDetailSQLFile) then begin
      _SQL.LoadFromFile(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__DiffDetailSQLFile)
    end      
    else 
      _SQL.Text := __Diff_SQL_Detail;
    if assigned(TClientDataSet(dsWork.DataSet)) then begin
      try
        _SQL.Text := ReplaceStr(_SQL.Text, __ECRPAY, IntToStr(TClientDataSet(dsWork.DataSet).FieldByName(__EcrPayID).AsInteger));
        __SelectData( _cds, _SQL.Text );
        _cds.First;
      except
        on E: Exception do begin
          ShowMessage(E.Message);
        end;
      end;
    end;
    FreeAndNil(_SQL);
  end;
end;

procedure TWorkForm.__GetAnnul(var _cds: TClientDataSet);
var
  _SQL: TStrings;
begin
  if __GetParams then begin
    _SQL := TStringList.Create;
    if FileExists(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__AnnulSQLFile) then begin
      _SQL.LoadFromFile(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__AnnulSQLFile)
    end      
    else 
      _SQL.Text := __Annul_SQL;
    _SQL.Text := ReplaceStr(_SQL.Text, __DATE_BEGIN, DateToStr(dtpBegin.Date));
    _SQL.Text := ReplaceStr(_SQL.Text, __DATE_END, DateToStr(dtpEnd.Date));
    __SelectData( _cds, _SQL.Text );
    FreeAndNil(_SQL);
    _cds.First;
  end;
end;

procedure TWorkForm.__GetSoldG(var _cds: TClientDataSet);
var
  _SQL: TStrings;
begin
  if __GetParams then begin
    _SQL := TStringList.Create;
    if FileExists(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__SoldDetailSQLFile) then begin
      _SQL.LoadFromFile(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__SoldDetailSQLFile)
    end      
    else 
      _SQL.Text := __SoldG_SQL;
    if __GoodsIdDetail <> 0 then begin
      _SQL.Text := ReplaceStr(_SQL.Text, __DATE_BEGIN, DateToStr(dtpBegin.Date));
      _SQL.Text := ReplaceStr(_SQL.Text, __DATE_END, DateToStr(dtpEnd.Date));
      _SQL.Text := ReplaceStr(_SQL.Text, __GOODSID, IntToStr(__GoodsIdDetail));
      __SelectData( _cds, _SQL.Text );
    end;
    FreeAndNil(_SQL);
    _cds.First;
  end;
end;

procedure TWorkForm.__GetAnnulDetail(var _cds: TClientDataSet);
var
  _SQL: TStrings;
begin
  if __GetParams then begin
    _SQL := TStringList.Create;
    if FileExists(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__AnnulDetailSQLFile) then begin
      _SQL.LoadFromFile(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__AnnulDetailSQLFile)
    end      
    else 
      _SQL.Text := __Annul_SQL_Detail;
    if assigned(TClientDataSet(dsWork.DataSet)) then begin
      try
        _SQL.Text := ReplaceStr(_SQL.Text, __ECRPAY, IntToStr(TClientDataSet(dsWork.DataSet).FieldByName(__EcrPayID).AsInteger));
        __SelectData( _cds, _SQL.Text );
        _cds.First;
      except
      end;
    end;
    FreeAndNil(_SQL);
  end;
end;

procedure TWorkForm.FormShow(Sender: TObject);
begin
  dtpBegin.Date := Date;
  dtpEnd.MinDate := IncDay(dtpBegin.Date, 1);
  __DataModified := true;
end;

procedure TWorkForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if assigned(__cdsWork) then FreeAndNil(__cdsWork);
  if assigned(__cdsWorkDetail) then FreeAndNil(__cdsWorkDetail);
end;

procedure TWorkForm.dtpBeginChange(Sender: TObject);
begin
  dtpEnd.MinDate := dtpBegin.Date;
  __DataModified := true;
end;

procedure TWorkForm.__GetSoldGDetailDetail(var _cds: TClientDataSet);
var
  _SQL: TStrings;
begin
  if __GetParams then begin
    _SQL := TStringList.Create;
    if FileExists(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__SoldGDetailDetailSQLFile) then begin
      _SQL.LoadFromFile(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__SoldGDetailDetailSQLFile)
    end      
    else 
      _SQL.Text := __SoldG_SQL_Detail;
    if assigned(TClientDataSet(dsWork.DataSet)) then begin
      try
        _SQL.Text := ReplaceStr(_SQL.Text, __ECRPAY, IntToStr(TClientDataSet(dsWork.DataSet).FieldByName(__EcrPayID).AsInteger));
        __SelectData( _cds, _SQL.Text );
        _cds.First;
      except
        on E: Exception do begin
          ShowMessage(E.Message);
        end;
      end;
    end;
    FreeAndNil(_SQL);
  end;
end;

procedure TWorkForm.__AfterSoldGScroll(DataSet: TDataSet);
var
  i: Integer;
begin
  if not assigned(__cdsWorkDetail) then
    __cdsWorkDetail := TClientDataSet.Create(nil);
  __GetSoldGDetailDetail(__cdsWorkDetail);
  dsWorkDetail.DataSet := TDataSet(__cdsWorkDetail);
  for i:=0 to dgWorkDetail.Columns.Count-1 do begin
    if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__SerNumber) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnSerNumber
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Moment) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnMoment
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Chknumber) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnChknumber
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Code) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnCode
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Name) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnName
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Price) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnPrice
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Quantity) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnQuantity
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Summa) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnSumma
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Discount) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnDiscount
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Total) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnTotal
    else dgWorkDetail.Columns.Items[i].Visible := false;
    if dgWorkDetail.Columns.Items[i].Visible then
      dgWorkDetail.Columns.Items[i].Width := Length(dgWorkDetail.Columns.Items[i].Title.Caption)*10;
  end;
end;

procedure TWorkForm.__AfterAnnulScroll(DataSet: TDataSet);
var
  i: Integer;
begin
  if not assigned(__cdsWorkDetail) then
    __cdsWorkDetail := TClientDataSet.Create(nil);
  __GetAnnulDetail(__cdsWorkDetail);
  dsWorkDetail.DataSet := TDataSet(__cdsWorkDetail);
  for i:=0 to dgWorkDetail.Columns.Count-1 do begin
    if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__SerNumber) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnSerNumber
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Moment) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnMoment
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Chknumber) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnChknumber
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Code) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnCode
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Name) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnName
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Price) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnPrice
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Quantity) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnQuantity
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Summa) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnSumma
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Discount) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnDiscount
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Total) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnTotal
    else dgWorkDetail.Columns.Items[i].Visible := false;
    if dgWorkDetail.Columns.Items[i].Visible then
      dgWorkDetail.Columns.Items[i].Width := Length(dgWorkDetail.Columns.Items[i].Title.Caption)*10;
  end;
end;

procedure TWorkForm.bSoldGGoClick(Sender: TObject);
var
  i: Integer;
  _Wait: TWait;
begin
  _Wait := TWait.Create(Self);
  _Wait.Show;
  Application.ProcessMessages;
  try
    if not assigned(__cdsWork) then begin
      __cdsWork := TClientDataSet.Create(nil);
    end;
    __GetSoldG(__cdsWork);
    dsWork.DataSet := TDataSet(__cdsWork);
    __cdsWork.AfterScroll := Self.__AfterSoldGScroll;
    for i:=0 to dgWork.Columns.Count-1 do begin
      if dgWork.Columns.Items[i].DisplayName = UpperCase(__SerNumber) then dgWork.Columns.Items[i].Title.Caption := __fnSerNumber
      else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Moment) then dgWork.Columns.Items[i].Title.Caption := __fnMoment
      else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Chknumber) then dgWork.Columns.Items[i].Title.Caption := __fnChknumber
      else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Paytype) then dgWork.Columns.Items[i].Title.Caption := __fnPaytype
      else if dgWork.Columns.Items[i].DisplayName = UpperCase(__TotalCHK) then dgWork.Columns.Items[i].Title.Caption := __fnTotalCHK
      else dgWork.Columns.Items[i].Visible := false;
      if dgWork.Columns.Items[i].Visible then
        dgWork.Columns.Items[i].Width := Length(dgWork.Columns.Items[i].Title.Caption)*10;
    end;
    __cdsWork.First;
  finally
    _Wait.Close;
    _Wait.Free;
  end;
end;

procedure TWorkForm.bDiffGoClick(Sender: TObject);
var
  i: Integer;
  _Wait: TWait;
begin
  _Wait := TWait.Create(Self);
  _Wait.Show;
  Application.ProcessMessages;
  try
    if (__DataModified) then begin
      if not assigned(__cdsWork) then begin
        __cdsWork := TClientDataSet.Create(nil);
      end;
      __GetDiff(__cdsWork);
      dsWork.DataSet := TDataSet(__cdsWork);
      __cdsWork.AfterScroll := Self.__AfterDiffScroll;
      for i:=0 to dgWork.Columns.Count-1 do begin
        if dgWork.Columns.Items[i].DisplayName = UpperCase(__SerNumber) then dgWork.Columns.Items[i].Title.Caption := __fnSerNumber
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Moment) then dgWork.Columns.Items[i].Title.Caption := __fnMoment
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Chknumber) then dgWork.Columns.Items[i].Title.Caption := __fnChknumber
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Paytype) then dgWork.Columns.Items[i].Title.Caption := __fnPaytype
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__TotalSTR) then dgWork.Columns.Items[i].Title.Caption := __fnTotalSTR
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__TotalCHK) then dgWork.Columns.Items[i].Title.Caption := __fnTotalCHK
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__TotalDiff) then dgWork.Columns.Items[i].Title.Caption := __fnTotalDiff
        else dgWork.Columns.Items[i].Visible := false;
        if dgWork.Columns.Items[i].Visible then
          dgWork.Columns.Items[i].Width := Length(dgWork.Columns.Items[i].Title.Caption)*10;
      end;
      __cdsWork.First;
      __DataModified := false;
    end;
  finally
    _Wait.Close;
    _Wait.Free;
  end;
end;


procedure TWorkForm.bAnnulGoClick(Sender: TObject);
var
  i: Integer;
  _Wait: TWait;
begin
  _Wait := TWait.Create(Self);
  _Wait.Show;
  Application.ProcessMessages;
  try
    if (__DataModified) then begin
      if not assigned(__cdsWork) then begin
        __cdsWork := TClientDataSet.Create(nil);
      end;
      __GetAnnul(__cdsWork);
      dsWork.DataSet := TDataSet(__cdsWork);
      __cdsWork.AfterScroll := Self.__AfterAnnulScroll;
      for i:=0 to dgWork.Columns.Count-1 do begin
        if dgWork.Columns.Items[i].DisplayName = UpperCase(__SerNumber) then dgWork.Columns.Items[i].Title.Caption := __fnSerNumber
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Moment) then dgWork.Columns.Items[i].Title.Caption := __fnMoment
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Chknumber) then dgWork.Columns.Items[i].Title.Caption := __fnChknumber
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Paytype) then dgWork.Columns.Items[i].Title.Caption := __fnPaytype
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__TotalSTR) then dgWork.Columns.Items[i].Title.Caption := __fnTotalSTR
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__TotalCHK) then dgWork.Columns.Items[i].Title.Caption := __fnTotalCHK
        else dgWork.Columns.Items[i].Visible := false;
        if dgWork.Columns.Items[i].Visible then
          dgWork.Columns.Items[i].Width := Length(dgWork.Columns.Items[i].Title.Caption)*10;
      end;
      __cdsWork.First;
      __DataModified := false;
    end;
  finally
  end;
end;

procedure TWorkForm.dtpEndChange(Sender: TObject);
begin
  __DataModified := true;
end;

procedure TWorkForm.__AfterDiffScroll(DataSet: TDataSet);
var
  i: Integer;
begin
  if not assigned(__cdsWorkDetail) then
    __cdsWorkDetail := TClientDataSet.Create(nil);
  __GetDiffDetail(__cdsWorkDetail);
  __cdsWorkDetail.BeforeDelete := Self.__DetailBeforeDiffDelete;
  __cdsWorkDetail.AfterDelete := Self.__DetailAfterDiffDelete;
  dsWorkDetail.DataSet := TDataSet(__cdsWorkDetail);
  for i:=0 to dgWorkDetail.Columns.Count-1 do begin
    if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__SerNumber) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnSerNumber
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Moment) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnMoment
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Chknumber) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnChknumber
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Code) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnCode
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Name) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnName
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Price) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnPrice
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Quantity) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnQuantity
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Summa) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnSumma
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Discount) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnDiscount
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Total) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnTotal
    else dgWorkDetail.Columns.Items[i].Visible := false;
    if dgWorkDetail.Columns.Items[i].Visible then
      dgWorkDetail.Columns.Items[i].Width := Length(dgWorkDetail.Columns.Items[i].Title.Caption)*10;
  end;
end;

procedure TWorkForm.__AfterChecksScroll(DataSet: TDataSet);
var
  i: Integer;
begin
  if not assigned(__cdsWorkDetail) then
    __cdsWorkDetail := TClientDataSet.Create(nil);
  __GetChecksDetail(__cdsWorkDetail);
  dsWorkDetail.DataSet := TDataSet(__cdsWorkDetail);
  for i:=0 to dgWorkDetail.Columns.Count-1 do begin
    if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__SerNumber) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnSerNumber
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Moment) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnMoment
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Chknumber) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnChknumber
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Code) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnCode
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Name) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnName
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Price) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnPrice
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Quantity) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnQuantity
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Summa) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnSumma
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Discount) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnDiscount
    else if dgWorkDetail.Columns.Items[i].DisplayName = UpperCase(__Total) then dgWorkDetail.Columns.Items[i].Title.Caption := __fnTotal
    else dgWorkDetail.Columns.Items[i].Visible := false;
    if dgWorkDetail.Columns.Items[i].Visible then
      dgWorkDetail.Columns.Items[i].Width := Length(dgWorkDetail.Columns.Items[i].Title.Caption)*10;
  end;
end;

procedure TWorkForm.__DelDiff(id: Integer);
var
  _SQL: TStrings;
begin
  if __GetParams then begin
    _SQL := TStringList.Create;
    if FileExists(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__DelDiffSQLFile) then begin
      _SQL.LoadFromFile(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__DelDiffSQLFile)
    end      
    else 
      _SQL.Text := __Diff_SQL_DelDiff;
    _SQL.Text := ReplaceStr(_SQL.Text, __SALESID, IntToStr(id));
    __DeleteData( _SQL.Text );
    FreeAndNil(_SQL);
  end;
end;

procedure TWorkForm.__DetailBeforeDiffDelete(DataSet: TDataSet);
begin
  __DelDiff(DataSet.FieldByName(__ID).AsInteger);
  __DataModified := true;
end;

procedure TWorkForm.__DetailAfterDiffDelete(DataSet: TDataSet);
begin
  bGo.Click;  
  dgWork.SetFocus;
end;

function TWorkForm.__FindProtocolFile(_Dir, _SN: String;
  _Date: TDateTime; var _Fn: String): Boolean;
var
  _sr: TSearchRec;
  _Dt: TDateTime;
begin
  Result := false;
  _Fn := _SN+FormatDateTime('ddmmyyyy',_Date)+__logext;
  if FileExists(_Dir+_Fn) then Result := true
  else begin
    if FindFirst(_Dir+_SN+'*'+__logext, faAnyFile, _sr)=0 then begin
      _Dt := StrToDateTime(Copy(Copy(_sr.Name, Length(_SN)+1, Length(_sr.Name) - Length(_SN)-4), 1, 2)+ DateSeparator+
                           Copy(Copy(_sr.Name, Length(_SN)+1, Length(_sr.Name) - Length(_SN)-4), 3, 2)+ DateSeparator+
                           Copy(Copy(_sr.Name, Length(_SN)+1, Length(_sr.Name) - Length(_SN)-4), 5, 4));
      if ((_Dt <= _Date) and (_Date <= FileDateToDateTime(_sr.Time))) then begin
        _FN := _sr.Name;
        Result := True;
        FindClose(_sr);
      end
      else
        try
          while FindNext(_sr)=0 do begin
            _Dt := StrToDateTime(Copy(Copy(_sr.Name, Length(_SN)+1, Length(_sr.Name) - Length(_SN)-4), 1, 2)+ DateSeparator+
                                 Copy(Copy(_sr.Name, Length(_SN)+1, Length(_sr.Name) - Length(_SN)-4), 3, 2)+ DateSeparator+
                                 Copy(Copy(_sr.Name, Length(_SN)+1, Length(_sr.Name) - Length(_SN)-4), 5, 4));
            if ((_Dt <= _Date) and (_Date < FileDateToDateTime(_sr.Time))) then begin
              _FN := _sr.Name;
              Result := True;
              break;
            end;
          end;
        finally
          FindClose(_sr);
        end;
    end;
  end;
end;

procedure TWorkForm.FormCreate(Sender: TObject);
begin
  fsWork.IniFileName := Copy(ParamStr(0), 1, LastDelimiter(PathDelimiter, ParamStr(0)))+'SellsMonitor.ini';
  __GoodsIdDetail := 0;
end;

procedure TWorkForm.dgWorkDblClick(Sender: TObject);
var
  _i,
  _SN: Integer;
  _Dt: TDateTime;
  _Fn: String;
  _ChkNum1: String;
  _ChkNum2: String;
  _BCount,
  _BytesRead,
  _fPos,
  _FileLen,
  _File:  Integer;
  _ResStream: TStrings;
  _ProcStr,
  _SearchStr1: String;
  _SearchStr2: String;
  _CheckRes,
  _WriteStr: Boolean;
  _LastBuffer,
  _Buffer: Byte;
  _opType: Byte;
  fListProtocol: TfListProtocol;
  fProgress: TfProgress;
  _WorkPos: Integer;
begin
  try
    _ResStream := nil; _WriteStr := false; _WorkPos := 0;
    _SN := dsWork.DataSet.FieldByName(__SerNumber).AsInteger;
    _ChkNum1 := IntToStr(dsWork.DataSet.FieldByName(__Chknumber).AsInteger-1);
    _ChkNum2 := IntToStr(dsWork.DataSet.FieldByName(__Chknumber).AsInteger);
    _Dt := dsWork.DataSet.FieldByName(__Moment).AsDateTime;
    if Length(__ProtocolDir)>0 then begin
      _Fn := '';
      if __FindProtocolFile(__ProtocolDir, IntToStr(_SN), _Dt, _Fn) then begin
        _File := FileOpen(__ProtocolDir+_Fn, fmShareDenyNone);
        if (_File > 0) then begin
          _FileLen := FileSeek(_File,0,2);
          FileSeek(_File,0,0);
          _SearchStr1 := DlmField+_ChkNum1+DlmField;
          _SearchStr2 := DlmField+_ChkNum2+DlmField;
          if not assigned(_ResStream) then _ResStream := TStringList.Create;
          _ProcStr := '';
          fProgress := TfProgress.Create(nil);
          fProgress.pbSearch.Max := _FileLen;
          fProgress.pbSearch.Step := 1;
          fProgress.Show;
          _LastBuffer := $00;
          for _fPos := 0 to _FileLen do begin
            _BCount := 1;
            _BytesRead := FileRead(_File, _Buffer, _BCount);
            fProgress.pbSearch.StepIt;        
            if _BytesRead = 1 then begin
              if (_Buffer = $0d) then begin
                if (_LastBuffer = $0d) then Inc(_WorkPos);
                if (_WorkPos = 0) then begin
                  if (_opType in [opSaleCode, opSaleBar]) then begin
                    if not _CheckRes then begin
                      if Copy(_ProcStr,2,2)='->' then begin
                        _ResStream[_ResStream.Count-1] := _ResStream[_ResStream.Count-1]+Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 7))+DlmField;
                        _WorkPos := 0;
                      end
                      else begin
                        _CheckRes := True;
                        _WorkPos := 1;
                        _ResStream[_ResStream.Count-1] := _ResStream[_ResStream.Count-1]+_ProcStr;
                      end;
                    end
                    else begin
                      if (ReplaceStr(_ProcStr,#$A,'')=#$06) then
                        _ResStream[_ResStream.Count-1] := '+;'+_ResStream[_ResStream.Count-1]
                      else
                        _ResStream[_ResStream.Count-1] := '-;'+_ResStream[_ResStream.Count-1];
                      _opType := FF;
                      _CheckRes := False;
                      _WorkPos := 0;
                    end;
                  end
                  else
                    if (Pos(_SearchStr1, _ProcStr)>0) or (Pos(_SearchStr2, _ProcStr)>0) then begin
                      try
                        if (Length(Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 3)))>0) then
                          _opType := Ord(StrFunc.ExtractWord(_ProcStr, DlmField,3)[1])
                        else _opType := FF;
                      except
                        _opType := FF;
                      end;
                      if (_opType = opPayment) or (_opType = opAnnul) then begin
                        _ResStream.Append('+;'+_ProcStr);
                        if (Pos(_SearchStr2, _ProcStr)>0) then begin
                          fProgress.pbSearch.StepBy(fProgress.pbSearch.Max - fProgress.pbSearch.Position);
                          break;
                        end;
                        _ProcStr := '';
                      end;
                      if (_opType in [opSaleCode, opSaleBar]) then begin
                        _WorkPos := 1;
                        _ResStream.Append(_ProcStr);
                      end;
                    end
                end
                else if (_WorkPos > 0) then dec(_WorkPos);
                _ProcStr := '';
              end
              else _ProcStr := _ProcStr + Char(_Buffer);
              _LastBuffer := _Buffer;
            end;
          end;
          fProgress.Close;
          fProgress.Free;
          FileClose(_File);
        end;
/////
        __ParseProtocol_Show(_ResStream);
        if (assigned(_ResStream)) then FreeAndNil(_ResStream);
      end
      else ShowMessage(__NoInfo);
    end
    else ShowMessage(__NoInfo);
  except
    on E: Exception do begin
      ShowMessage(E.Message);
    end;
  end;
end;

procedure TWorkForm.__ParseProtocol_Show(var _Stream: TStrings);
var
  _i: Integer;
  _opType: Byte;
  fKnd: Integer;
  fTime, fCass, fOper,
  fRes, fCheck, fCode,
  fName, fPrice, fCount: String;
  _Knd: Integer;
  _ProcStr: String;
  fListProtocol: TfListProtocol;
begin
  if (assigned(_Stream) and (_Stream.Count>0)) then begin
    fListProtocol := TfListProtocol.Create(dgWork);
    fListProtocol.__PrepareDataSet;
    _i := 0;
    while _i < _Stream.Count do begin
      _ProcStr := ReplaceStr(_Stream.Strings[_i],#10,'');
      try
        if (Length(Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 4)))>0) then
          _opType := Ord(StrFunc.ExtractWord(_ProcStr, DlmField,4)[1])
        else _opType := FF;
      except
        _opType := FF;
      end;
      if _opType = opPayment then begin
        try
          if (Length(Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 5)))>0) then
            _opType := Ord(StrFunc.ExtractWord(_ProcStr, DlmField,5)[1])
          else _opType := FF;
        except
          _opType := FF;
        end;
        case _opType of
          Ord(__kndNullCheck): ;
          Ord(__kndInOut): ;
          else _opType := opPayment;
        end;
      end;
      case _opType of
        opSaleCode, 
        opSaleBar: begin
          fTime := Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 11));
          fCass := IntToStr(StrToInt(Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 2))));
          if _opType = opSaleCode then fOper := resSaleCode
          else fOper := resSaleBar;
          fKnd := 0;
          fCheck := Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 9));
          fCode := Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 5));
          fName := Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 13));
          fPrice := Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 14));
          fCount := Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 7));
          if Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 1))='-' then begin
            fRes := resError;
            fKnd := 2;
          end
          else begin 
            fRes := '';
            if (fName = fPrice) then begin
              fRes := resNoGoodsParam;
              fKnd := 2;
            end;
          end;
        end;
        opPayment: begin
          fKnd := 3;
          fTime := '';
          fCass := IntToStr(StrToInt(Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 2))));
          DecimalSeparator := '.';
          try
            if (StrToFloat(Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 12))) - 
               StrToFloat(Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 13)))) > 0.009 then
              fOper := resPrtPayment
            else
              fOper := resPayment;
          except
            fOper := resPayment;
          end;
          if Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 2))='-' then begin
            fRes := resError;
            fKnd := 4;
          end
          else fRes := '';
          fCheck := Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 10));
          try
            _Knd := StrToInt(Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 5)));
          except
            _Knd := 0;
          end;
          case _Knd of
            0: fCode := '��������';
            else
              fCode := '������';
          end;
          fName := '';
          fPrice := Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 12));
          fCount := Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 13));
        end;
        Ord(__kndNullCheck): begin
          fKnd := 3;
          fTime := '';
          fCass := IntToStr(StrToInt(Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 2))));
          fOper := resNullCheck;
          fCode := '';
          fRes := '';
          fCheck := Trim(StrFunc.ExtractWord(_ProcStr, DlmField, 10));
          fName := '';
          fPrice := '';
          fCount := '';
        end;
        Ord(__kndInOut): ;
      end;
      fListProtocol.rmdProtocol.AppendRecord([fKnd, fTime, fCass, fOper,
                                              fRes, fCheck, fCode,
                                              fName, fPrice, fCount]);
      inc(_i);
    end;
    fListProtocol.ShowModal;
    fListProtocol.Free; 
  end
  else ShowMessage(__NoInfo);
end;


procedure TWorkForm.dgWorkKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then dgWorkDblClick(Sender);
end;

procedure TWorkForm.__GetSold(var _cds: TClientDataSet);
var
  _SQL: TStrings;
begin
  if __GetParams then begin
    _SQL := TStringList.Create;
    if FileExists(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__SoldGoodsSQLFile) then begin
      _SQL.LoadFromFile(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__SoldGoodsSQLFile)
    end      
    else 
      _SQL.Text := __Sold_SQL;
    _SQL.Text := ReplaceStr(_SQL.Text, __DATE_BEGIN, DateToStr(dtpBegin.Date));
    _SQL.Text := ReplaceStr(_SQL.Text, __DATE_END, DateToStr(dtpEnd.Date));
    __SelectData( _cds, _SQL.Text );
    FreeAndNil(_SQL);
    _cds.First;
  end;
end;

procedure TWorkForm.bSoldGoClick(Sender: TObject);
var
  i: Integer;
  _Wait: TWait;
begin
  _Wait := TWait.Create(Self);
  _Wait.Show;
  Application.ProcessMessages;
  try
    if (__DataModified) then begin
      if not assigned(__cdsWork) then begin
        __cdsWork := TClientDataSet.Create(nil);
      end;
      __GetSold(__cdsWork);
      dsWork.DataSet := TDataSet(__cdsWork);
      for i:=0 to dgWork.Columns.Count-1 do begin
        if dgWork.Columns.Items[i].DisplayName = UpperCase(__Code) then dgWork.Columns.Items[i].Title.Caption := __fnCode
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Name) then dgWork.Columns.Items[i].Title.Caption := __fnName
        else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Quantity) then dgWork.Columns.Items[i].Title.Caption := __fnQuantity
        else dgWork.Columns.Items[i].Visible := false;
        if dgWork.Columns.Items[i].Visible then
          dgWork.Columns.Items[i].Width := Length(dgWork.Columns.Items[i].Title.Caption)*10;
      end;
      __cdsWork.First;
      __DataModified := false;
    end;
  finally
    _Wait.Close;
    _Wait.Free;
  end;
end;

procedure TWorkForm.bChecksGoClick(Sender: TObject);
var
  i: Integer;
  _Wait: TWait;
begin
  _Wait := TWait.Create(Self);
  _Wait.Show;
  Application.ProcessMessages;
  try
    if not assigned(__cdsWork) then begin
      __cdsWork := TClientDataSet.Create(nil);
    end;
    __GetChecks(__cdsWork);
    dsWork.DataSet := TDataSet(__cdsWork);
    __cdsWork.AfterScroll := Self.__AfterChecksScroll;
    for i:=0 to dgWork.Columns.Count-1 do begin
      if dgWork.Columns.Items[i].DisplayName = UpperCase(__SerNumber) then dgWork.Columns.Items[i].Title.Caption := __fnSerNumber
      else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Moment) then dgWork.Columns.Items[i].Title.Caption := __fnMoment
      else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Chknumber) then dgWork.Columns.Items[i].Title.Caption := __fnChknumber
      else if dgWork.Columns.Items[i].DisplayName = UpperCase(__Paytype) then dgWork.Columns.Items[i].Title.Caption := __fnPaytype
      else if dgWork.Columns.Items[i].DisplayName = UpperCase(__TotalCHK) then dgWork.Columns.Items[i].Title.Caption := __fnTotalCHK
      else dgWork.Columns.Items[i].Visible := false;
      if dgWork.Columns.Items[i].Visible then
        dgWork.Columns.Items[i].Width := Length(dgWork.Columns.Items[i].Title.Caption)*10;
    end;
    __cdsWork.First;
  finally
    _Wait.Close;
    _Wait.Free;
  end;
end;

procedure TWorkForm.dgSoldDblClick(Sender: TObject);
var
  _SoldGoodsDetail: TWorkForm;
begin
  _SoldGoodsDetail := TWorkForm.Create(nil);
  _SoldGoodsDetail.fsWork.IniSection := 'F_SOLD';
  _SoldGoodsDetail.Caption := __SoldFName+': '+
                              TDataSet(dsWork.DataSet).FieldByName(__Code).AsString+' '+
                              TDataSet(dsWork.DataSet).FieldByName(__Name).AsString;
  _SoldGoodsDetail.__GoodsIdDetail := TDataSet(dsWork.DataSet).FieldByName(__GID).AsInteger;
  _SoldGoodsDetail.fsWork.Active := True;
  _SoldGoodsDetail.dtpBegin.Date := dtpBegin.Date;
  _SoldGoodsDetail.dtpEnd.Date := dtpEnd.Date;
  _SoldGoodsDetail.bGo.Visible := False;
  _SoldGoodsDetail.dtpBegin.Enabled := False;
  _SoldGoodsDetail.dtpEnd.Enabled := False;
  _SoldGoodsDetail.dgWork.OnDblClick := _SoldGoodsDetail.dgWorkDblClick;
  _SoldGoodsDetail.dgWork.OnKeyPress := _SoldGoodsDetail.dgWorkKeyPress;
  _SoldGoodsDetail.bSoldGGoClick(Sender);
  _SoldGoodsDetail.ShowModal;  
  FreeAndNil(_SoldGoodsDetail);
end;

procedure TWorkForm.dgSoldKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) and (not dgWork.DataSource.DataSet.IsEmpty)  then dgSoldDblClick(Sender);
end;

procedure TWorkForm.dgWorkGetCellParams(Sender: TObject; Field: TField;
  AFont: TFont; var Background: TColor; Highlight: Boolean);
begin
  Try
    if Highlight then AFont.Color := TColor($0000FF);
    if (dgWork.DataSource.DataSet.FieldByName(dgWork.DataSource.DataSet.Fields[dgWork.DataSource.DataSet.FieldCount - 1].FieldName).AsFloat > 0) then
      Background := TColor($C0C0FF)
    else
      Background := TColor($C0FFC0);
  except
  end;
end;

procedure TWorkForm.dgWorkGetCellParamsForChecks(Sender: TObject; Field: TField;
  AFont: TFont; var Background: TColor; Highlight: Boolean);
begin
  Try
    if Highlight then AFont.Color := TColor($0000FF);
    if (dgWork.DataSource.DataSet.FieldByName(dgWork.DataSource.DataSet.Fields[dgWork.DataSource.DataSet.FieldCount - 1].FieldName).AsFloat > 0) then begin
      AFont.Style := [fsBold];
      AFont.Color := clNavy;
      Background := TColor($FFF080);
    end
    else begin
      AFont.Style := [fsBold];
      AFont.Color := clWhite;
      Background := TColor($C0C0FF)
    end;
  except
  end;
end;

procedure TWorkForm.SoldFilterExecute(Sender: TObject);
var 
  InputString: String;    
begin
  if ((Self.ActiveControl = dgWork) and (not dgWork.DataSource.DataSet.IsEmpty)) then begin
    InputString:= InputBox(Self.Caption, '������� ���', '');
    if (Length(InputString)>0) then
      if not dsWork.DataSet.Locate(dsWork.DataSet.Fields[1].FieldName, InputString, [loCaseInsensitive]) then
        ShowMessage('����� �� ������.');
  end;
end;

procedure TWorkForm.ChecksFilterExecute(Sender: TObject);
var 
  InputString: String;    
begin
  if ((Self.ActiveControl = dgWork) and (not dgWork.DataSource.DataSet.IsEmpty)) then begin
    InputString:= InputBox(Self.Caption, '������� �.�. �����', '');
    if (Length(InputString)>0) then begin
      dsWork.DataSet.FilterOptions := [foCaseInsensitive, foNoPartialCompare];
      dsWork.DataSet.Filter := 'SerNumber = '+InputString;
      dsWork.DataSet.Filtered := True;
    end
    else begin
      dsWork.DataSet.Filter := '';
      dsWork.DataSet.FilterOptions := [];
      dsWork.DataSet.Filtered := False;
    end;
  end;
end;

procedure TWorkForm.__GetChecks(var _cds: TClientDataSet);
var
  _SQL: TStrings;
begin
  if __GetParams then begin
    _SQL := TStringList.Create;
    if FileExists(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__ChecksGoodsSQLFile) then begin
      _SQL.LoadFromFile(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__ChecksGoodsSQLFile)
    end      
    else 
      _SQL.Text := __Checks_SQL;
    _SQL.Text := ReplaceStr(_SQL.Text, __DATE_BEGIN, DateToStr(dtpBegin.Date));
    _SQL.Text := ReplaceStr(_SQL.Text, __DATE_END, DateToStr(dtpEnd.Date));
    __SelectData( _cds, _SQL.Text );
    FreeAndNil(_SQL);
    _cds.First;
  end;
end;

procedure TWorkForm.__GetChecksDetail(var _cds: TClientDataSet);
var
  _SQL: TStrings;
begin
  if __GetParams then begin
    _SQL := TStringList.Create;
    if FileExists(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__ChecksGoodsSQLFile) then begin
      _SQL.LoadFromFile(Copy(ParamStr(0), 1, LastDelimiter(__PathDelimiter, ParamStr(0)))+__PathDelimiter+__ChecksGoodsSQLFile)
    end      
    else 
      _SQL.Text := __Checks_SQL_Detail;
    if assigned(TClientDataSet(dsWork.DataSet)) then begin
      try
        _SQL.Text := ReplaceStr(_SQL.Text, __ECRPAY, IntToStr(TClientDataSet(dsWork.DataSet).FieldByName(__EcrPayID).AsInteger));
        __SelectData( _cds, _SQL.Text );
        _cds.First;
      except
        on E: Exception do begin
          ShowMessage(E.Message);
        end;
      end;
    end;
    FreeAndNil(_SQL);
  end;
end;

{$ifdef UpdateDB}
procedure TWorkForm.UpdateDB;
begin
  if __GetParams then begin
    UpdateDB_ToLastVer(__DB_FileName, __DB_user, __DB_pass);
    SyncDB_MTU(__DB_FileName, __DB_user, __DB_pass);
  end;
end;
{$endif}

end.
