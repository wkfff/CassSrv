unit DataStream;

interface
  uses  Windows, Messages, LogFunc,
  ConnectionStream, Const_Type, SysUtils,
{$ifdef debug}  
  fDbGrid,
{$endif}  
  ProcessDBObj, DBClient, myIBEvents, StrFunc;
  
type

  PDataStream = ^TDataStream;
  TDataStream = class
    private
      __HParseQueryDiscLiblary,
      __HParseBarLibrary,
		  __HLibrary: THandle;
      __ConnectionStream: TConnectionStream;
      __TimeOut:   Integer;
      __Terminated: Boolean;
      __DevEnum: PDevEnum;
      __MainTHId: Cardinal;
      __StreamHandle: THandle;
      __StreamThID: Cardinal;
      __Port: Integer;
      __PortID: Integer;
      __BaudNumber: Integer;
{$ifdef CS}      
      __CS: TRTLCriticalSection;
      __CSDev: TRTLCriticalSection;
{$else}      
      __EvH: Cardinal;
      __EvHDev: Cardinal;
{$endif}      
		  __EventLogger: TEventLogger;

      __Goods: TClientDataSet;
      __BarCodes: TClientDataSet;
      __DepPrice: TClientDataSet;
      __Ecrs: TClientDataSet;

      ___InitParseQueryDisc: TInitParseQueryDisc;
      ___InitParseBar: TInitParseBar;
      ___ParseQueryDisc: TParseQueryDisc;
      ___ParseBar: TParseBar;
      
      __DBObj: TSecondDBObj;

      __SaveServiceCheck: Integer;
      __WriteProtocol: Integer;
      __WriteFullProtocol: Integer;
      __RejectNoAnswer: Integer;
      __NoRejectIfNull: Integer;
      __SendNullIfReadError: Integer;

      __TmpDir, __GoodsCashe,
      __ProtocolDir,
      __PQDLibraryName,
      __PBLibraryName: String;
    private
    protected
      procedure __Terminate; virtual;
      function __GetParams: Boolean; virtual;
      procedure __CheckTmpCDS; virtual;
      procedure __CreateDevEnum(_DevArray: TDevArray); virtual;
      function __GoodsCasheCreate(): TClientDataSet; virtual;
      function __OpenGoodsCashe(_DevEnum: PDevEnum): TClientDataSet; virtual;
      procedure __FreeDevEnum; virtual;
      procedure __CloseStream; virtual;
      function __GetGoodsParam(var _P: TGoodsParam; _DevEnum: PDevEnum): Boolean; virtual;
      function __ParseBar( var _P: TGoodsParam; _DevEnum: PDevEnum ): Boolean; virtual;
      function __ParseKey( _Key: String; _DevEnum: PDevEnum ): String; virtual;
      function __ParseQueryDisc( _ChkNum: Integer; _Perc, _BSum: Double; var _tDKnd: Integer; _DevEnum: PDevEnum): Double; virtual;

      procedure __SaleArt(_P: Pointer; _DevEnum: PDevEnum); virtual;
      procedure __Payment(_P: Pointer; _DevEnum: PDevEnum); virtual;
      procedure __Annul(_P: Pointer; _DevEnum: PDevEnum); virtual;
      procedure __QueryDisc(_P: Pointer; _DevEnum: PDevEnum); virtual;
      procedure __SaleCode(_P: Pointer; _DevEnum: PDevEnum); virtual;
      procedure __Discount(_P: Pointer; _DevEnum: PDevEnum); virtual;
      procedure __SaleBar(_P: Pointer; _DevEnum: PDevEnum); virtual;
      procedure __QueryKey(_P: Pointer; _DevEnum: PDevEnum); virtual;
      procedure __RejectLastOperation(_P: Pointer; _DevEnum: PDevEnum); virtual;
      procedure __RejectSaleCode(_P: Pointer; _DevEnum: PDevEnum); virtual;
      procedure __RejectSaleBar(_P: Pointer; _DevEnum: PDevEnum); virtual;
      procedure __ProcEventsAlert( _cds: TClientDataSet; _case: Integer ); virtual;
      procedure __RefreshGoodsCashe(_case: Integer); virtual;
    public
      constructor Create;
		  destructor Destroy; override;
      function InitializeStream( _P: Pointer ): BOOL; virtual;
      procedure Terminate; virtual;
      procedure WaitForExit; virtual;
      procedure Resume; virtual;
      procedure Initialize; virtual;
      procedure Finalize; virtual;
      procedure Run; virtual;
      procedure ProcessPacket(_P: Pointer; _OpData: POpData); virtual;
      procedure ConfirmAnnul(_DevEnum: PDevEnum); virtual;
    published
      property Terminated: Boolean read __Terminated write __Terminated;
      property StreamThID: Cardinal read __StreamThID;
      property MainThID: Cardinal write __MainThID;
      property HLibrary: THandle read __HLibrary write __HLibrary;
      property Port: Integer read __Port write __Port;
      property PortID: Integer read __PortID write __PortID;
      property BaudNumber: Integer read __BaudNumber write __BaudNumber;
      property TmpDir: String read __TmpDir;
      property EventLogger: TEventLogger read __EventLogger;
  end;

implementation

uses 
  StrUtils, Protocols,
  ShowErrorFunc, CheckState,
  db;
  
{ TDataStream }

function DataStreamThreadProc( lpData: Pointer ): DWORD stdcall;
var
  __DataStream: TDataStream;   
begin
  Result := 0;
  try
    __DataStream := TDataStream(lpData);
    __DataStream.Initialize;
    __DataStream.Run;
    __DataStream.Finalize;
  except
    on e: Exception do begin
      __DataStream.__EventLogger.LogError('500_DataStreamThreadProc exception: '+e.Message);
      Result := $FFFFFFFF;
    end;
  end;
  ExitThread(Result);
end;

function TDataStream.__GetGoodsParam(var _P: TGoodsParam; _DevEnum: PDevEnum): Boolean;
var
  _IdGoods: Integer;
  _F_Code, 
  _F_Name, _F_GID,
  _F_Price, _F_TaxID: TField;
{$ifndef CS}
  _TimeOut: Integer;
{$endif}  
begin
  Result := False;
  try
{$ifndef CS}
    if __TimeOut = 0 then
      _TimeOut := INFINITE
    else _TimeOut := 2000;
    if WaitForSingleObject(__EvH, _TimeOut) = WAIT_OBJECT_0 then begin
{$else}
    EnterCriticalSection(__CS);
{$endif}  
      if assigned(__Goods) and assigned(__BarCodes) and assigned(__DepPrice) then begin
        try
          _IdGoods := 0; 
          _F_Code := __Goods.FieldByName('CODE');
          _F_Name := __Goods.FieldByName('ECRNAME');
          _F_Price := __DepPrice.FieldByName('PRICE');
          _F_TaxID := __DepPrice.FieldByName('TAXID');
          _P.Dividable := True;
          if _P.isBarCode then begin
            _P.Zoom := 1;
            _F_GID := __BarCodes.FieldByName('GOODSID');
            __BarCodes.IndexName := 'Idx_BARCODE';
            __BarCodes.EditKey;
            __BarCodes.FieldByName('BARCODE').AsString := _P.BarCode;
            if __BarCodes.GotoKey then begin
              _P.Zoom := __BarCodes.FieldByName('ZOOM').AsFloat;
              _IdGoods := _F_GID.AsInteger;
              __Goods.IndexName := 'Idx_ID';
              __Goods.EditKey;
              __Goods.FieldByName('ID').AsInteger := _IdGoods;
            end;
          end
          else begin
            _F_GID := __Goods.FieldByName('ID');
            __Goods.IndexName := 'Idx_CODE';
            __Goods.EditKey;
            __Goods.FieldByName('CODE').AsInteger := StrToInt(_P.Code);
          end;
          if ( ( _P.isBarCode and ( _IdGoods > 0 ) ) 
            or ( not _P.isBarCode ) ) then
            if __Goods.GotoKey then begin
              _IdGoods := _F_GID.AsInteger;
              _P.Code := _F_Code.AsString;
              _P.Name := _P.Code+'.'+_F_Name.AsString;
              if __Goods.FieldByName('CHKINTEGER').AsString = 'F' then _P.Dividable := True
              else _P.Dividable := False;
              __DepPrice.IndexName := 'Idx_GOOD_DEPART';
              __DepPrice.EditKey;
              __DepPrice.FieldByName('GOODSID').AsInteger := _IdGoods;
              __DepPrice.FieldByName('DEPARTID').AsInteger := _DevEnum^.Depart;
              _P.GoodsID := IntToStr(_IdGoods);
              if __DepPrice.GotoKey then begin
                _P.OriginalPrice := Trunc(_F_Price.AsCurrency * 100+0.5)/100;
                if (Trunc(_P.Zoom * 100000+0.5)/100 > 1000) then begin
                  _P.Price := CurrToStr(Trunc(_P.Zoom * _F_Price.AsCurrency * 100+0.5)/100);
                end
                else
                  _P.Price := _F_Price.AsString;
                case Length(StrFunc.ExtractWord( _P.Price, _DS, 2)) of
                  0: _P.Price := _P.Price + '.00';
                  1: _P.Price := _P.Price + '0';
                end;
                _P.Tax := _F_TaxID.AsString;
                if Length( _P.Tax ) = 0 then _P.Tax := '0';
                if Length(_P.Name) < 18 then 
                  _P.Name := StrUtils.LeftStr(_P.Name,18)
                else
                  _P.Name := Copy(_P.Name, 1, 18);
                _P.Name := WinStrToDatecs(_P.Name);
                Result := (((not _P.Dividable) and ( Round(StrToFloat(_P.Count)) = StrToFloat(_P.Count))) or _P.Dividable);
                if Result then
                  with TClientDataSet(_DevEnum^.GoodsCash) do begin 
                    try
                      if _P.isBarCode then IndexName := 'idxMainFull'
                      else IndexName := 'IdxMainShort';
                      EditKey;
                      if _P.isBarCode then FieldByName('BarCode').AsString := _P.BarCode;
                      FieldByName('Code').AsString := _P.Code;
                      FieldByName('GoodsID').AsString := _P.GoodsID;
                      FieldByName('Name').AsString := _P.Name;
                      FieldByName('Tax').AsInteger := StrToInt(_P.Tax);
                      FieldByName('Price').AsCurrency := StrToCurr(_P.Price);
                      FieldByName('ChkInteger').AsBoolean := not _P.Dividable;
                      if GotoKey then begin
                        _P.EcrCode := FieldByName('EcrCode').AsString;
                      end
                      else begin
                        try
                          Append;
                          if _P.isBarCode then FieldByName('BarCode').AsString := _P.BarCode;
                          FieldByName('Code').AsString := _P.Code;
                          FieldByName('GoodsID').AsString := _P.GoodsID;
                          FieldByName('Name').AsString := _P.Name;
                          FieldByName('Tax').AsInteger := StrToInt(_P.Tax);
                          FieldByName('Price').AsCurrency := StrToCurr(_P.Price);
                          FieldByName('ChkInteger').AsBoolean := not _P.Dividable;
                          _DevEnum^.LastEcrCode := _DevEnum^.LastEcrCode + 1;
                          FieldByName('EcrCode').AsInteger := _DevEnum^.LastEcrCode;
                          Post;
                          _P.EcrCode := FieldByName('EcrCode').AsString;
                          try
                            SaveToFile(__GoodsCashe+IntToStr(_DevEnum^.SerialNum)+__dbext);
                          finally
                          end;
                        except
                          on e: Exception do begin
                            __EventLogger.LogError('500_TDataStream.__GetGoodsParam exception 1: '+e.Message);
                            Cancel;
                          end;
                        end;
                      end;
                    except
                      on e: Exception do begin
                        __EventLogger.LogError('500_TDataStream.__GetGoodsParam exception 2: '+e.Message);
                        Result := False;
                      end;
                    end;  
                  end; 
              end;
            end;
        except
          on e: Exception do begin
            __EventLogger.LogError('550_TDataStream.__GetGoodsParam exception: '+e.Message);
            Result := False;
          end;
        end;  
      end;
{$ifndef CS}
    end
    else
      __EventLogger.LogError('500_TDataStream.__GetGoodsParam __EvH timeout');
{$endif}  
  finally
{$ifdef CS}
    LeaveCriticalSection(__CS);
{$else}  
    SetEvent(__EvH);
{$endif}  
  end;
end;

procedure TDataStream.__CloseStream;
begin
  if not __Terminated then Terminate;
  if BOOL(__StreamHandle) then begin
    WaitForSingleObject(__StreamHandle, INFINITE);    
    CloseHandle(__StreamHandle);
    __StreamHandle := 0;
  end;
end;

procedure TDataStream.__CheckTmpCDS;
var
  _tmp: PDevEnum;
  _sr: TSearchRec;
  _cds: TClientDataSet;
  _sdr: PSaveDataRec;
  _Log:  TLog;
begin
  _tmp := __DevEnum;
  _Log := nil;
  while (true and assigned(_tmp)) do begin
    try
      _tmp := _tmp^.Next;
      if ( FindFirst(__TmpDir+IntToStr(_tmp^.SerialNum)+__tmpast+__tmpext, faAnyFile, _sr) = 0) then begin
        try
          _Log := TLog.Create(__TmpDir+IntToStr(_tmp^.SerialNum)+__tmpand);
          _cds := TClientDataSet.Create(nil);
          try
            _cds.LoadFromFile(__TmpDir+_sr.Name);
            _cds.LogChanges := false;
            if _cds.RecordCount > 0 then begin
              if _cds.FieldByName('Operation').AsInteger in 
                 [__opPayment, __opAnnul, __opInOut, __opNullCheck] then begin
                GetMem(_sdr, SizeOf(TSaveDataRec));
                FillChar(_sdr^,SizeOf(TSaveDataRec),$00);
                _sdr^.__CheckData := Pointer(_cds);
                SetString(_sdr^.__FileName,PChar(__TmpDir+_sr.Name),Length(__TmpDir+_sr.Name));
                SetString(_sdr^.__TmpDir,PChar(__TmpDir),Length(__TmpDir));
                _cds := nil;
                if assigned(_sdr) then begin
                  _Log.WriteToLog(PChar(DateTimeToStr(Now)+': V '+_sr.Name+' '+DateTimeToStr(FileDateToDateTime(FileAge(__TmpDir+_sr.Name)))),
                                  Length(DateTimeToStr(Now)+': V '+_sr.Name+' '+DateTimeToStr(FileDateToDateTime(FileAge(__TmpDir+_sr.Name)))));
                  PostThreadMessage(__MainTHId,THREAD_PROCESS_DATA,0,Cardinal(_sdr));
                end;
              end 
              else begin
                _Log.WriteToLog(PChar(DateTimeToStr(Now)+': - '+_sr.Name+' '+DateTimeToStr(FileDateToDateTime(FileAge(__TmpDir+_sr.Name)))),
                                Length(DateTimeToStr(Now)+': - '+_sr.Name+' '+DateTimeToStr(FileDateToDateTime(FileAge(__TmpDir+_sr.Name)))));
                if not assigned(TCheckState(_tmp^.CheckState).__CheckData) then begin
                  TCheckState(_tmp^.CheckState).__CheckData := _cds;
                  TCheckState(_tmp^.CheckState).__FileName := __TmpDir+_sr.Name;
                end
                else begin
                  try
                    TClientDataSet(TCheckState(_tmp^.CheckState).__CheckData).AppendData(_cds.Data, true);
                    TClientDataSet(TCheckState(_tmp^.CheckState).__CheckData).SaveToFile(TCheckState(_tmp^.CheckState).__FileName);
                  except
                    on e: Exception do begin
                      __EventLogger.LogError('500_TClientDataSet(TCheckState(_tmp^.CheckState).__CheckData).AppendData exception 1: '+e.Message);
                    end;
                  end;                    
                  _cds.Close;
                  _cds.Free;
                  DeleteFile(__TmpDir+_sr.Name);
                end;
              end;
            end
            else begin
              _cds.Close;
              _cds.Free;
              DeleteFile(__TmpDir+_sr.Name);
            end;
          except
            on e: Exception do begin
              __EventLogger.LogError('500__TDataStream.__CheckTmpCDS loading data file:'+__TmpDir+_sr.Name+' exception: '+e.Message);
              _Log.WriteToLog(PChar(DateTimeToStr(Now)+': - '+_sr.Name+' '+DateTimeToStr(FileDateToDateTime(FileAge(__TmpDir+_sr.Name)))),
                              Length(DateTimeToStr(Now)+': - '+_sr.Name+' '+DateTimeToStr(FileDateToDateTime(FileAge(__TmpDir+_sr.Name)))));
              _cds.Close;
              _cds.Free;
              DeleteFile(__TmpDir+_sr.Name);
            end;
          end;  
        except
          on e: Exception do begin
            __EventLogger.LogError('500__TDataStream.__CheckTmpCDS exception 2: '+e.Message);
          end;
        end;
        while (FindNext(_sr) = 0) do begin
          try
            _cds := TClientDataSet.Create(nil);
            try
              _cds.LoadFromFile(__TmpDir+_sr.Name);
              _cds.LogChanges := false;
              if _cds.RecordCount > 0 then begin
                if _cds.FieldByName('Operation').AsInteger in 
                   [ __opPayment, __opAnnul, __opInOut, __opNullCheck] then begin
                  GetMem(_sdr, SizeOf(TSaveDataRec));
                  FillChar(_sdr^,SizeOf(TSaveDataRec),$00);
                  _sdr^.__CheckData := Pointer(_cds);
                  SetString(_sdr^.__FileName,PChar(__TmpDir+_sr.Name),Length(__TmpDir+_sr.Name));
                  SetString(_sdr^.__TmpDir,PChar(__TmpDir),Length(__TmpDir));
                  _cds := nil;
                  if assigned(_sdr) then begin
                    _Log.WriteToLog(PChar(DateTimeToStr(Now)+': V '+_sr.Name+' '+DateTimeToStr(FileDateToDateTime(FileAge(__TmpDir+_sr.Name)))),
                                    Length(DateTimeToStr(Now)+': V '+_sr.Name+' '+DateTimeToStr(FileDateToDateTime(FileAge(__TmpDir+_sr.Name)))));
                    PostThreadMessage(__MainTHId,THREAD_PROCESS_DATA,0,Cardinal(_sdr));
                  end;
                end
                else begin
                  _Log.WriteToLog(PChar(DateTimeToStr(Now)+': - '+_sr.Name+' '+DateTimeToStr(FileDateToDateTime(FileAge(__TmpDir+_sr.Name)))),
                                  Length(DateTimeToStr(Now)+': - '+_sr.Name+' '+DateTimeToStr(FileDateToDateTime(FileAge(__TmpDir+_sr.Name)))));
                  if not assigned(TCheckState(_tmp^.CheckState).__CheckData) then begin
                    TCheckState(_tmp^.CheckState).__CheckData := _cds;
                    TCheckState(_tmp^.CheckState).__FileName := __TmpDir+_sr.Name;
                  end 
                  else begin
                    try
                      TClientDataSet(TCheckState(_tmp^.CheckState).__CheckData).AppendData(_cds.Data, true);
                      TClientDataSet(TCheckState(_tmp^.CheckState).__CheckData).SaveToFile(TCheckState(_tmp^.CheckState).__FileName);
                    except
                      on e: Exception do begin
                        __EventLogger.LogError('500_TClientDataSet(TCheckState(_tmp^.CheckState).__CheckData).AppendData exception 2: '+e.Message);
                      end;
                    end;                    
                    _cds.Close;
                    _cds.Free;
                    DeleteFile(__TmpDir+_sr.Name);
                  end;
                end;                
              end
              else begin
                _cds.Close;
                _cds.Free;
                DeleteFile(__TmpDir+_sr.Name);
              end;
            except
              on e: Exception do begin
                __EventLogger.LogError('500__TDataStream.__CheckTmpCDS loading data file:'+__TmpDir+_sr.Name+' exception: '+e.Message);
                _Log.WriteToLog(PChar(DateTimeToStr(Now)+': - '+_sr.Name+' '+DateTimeToStr(FileDateToDateTime(FileAge(__TmpDir+_sr.Name)))),
                                Length(DateTimeToStr(Now)+': - '+_sr.Name+' '+DateTimeToStr(FileDateToDateTime(FileAge(__TmpDir+_sr.Name)))));
                _cds.Close;
                _cds.Free;
                DeleteFile(__TmpDir+_sr.Name);
              end;
            end;
          except
            on e: Exception do begin
              __EventLogger.LogError('500_TDataStream.__CheckTmpCDS exception 2: '+e.Message);
            end;
          end;
        end;
        FindClose(_sr);
        if assigned(_Log) then FreeAndNil(_Log);
      end;
      if (_tmp = __DevEnum) then break;
    except
      on e: Exception do begin
        __EventLogger.LogError('500_TDataStream.__CheckTmpCDS exception: '+e.Message);
      end;
    end;
  end;
end;

function TDataStream.__GoodsCasheCreate(): TClientDataSet;
var
  _tmp: TClientDataSet;
begin
  try
    _tmp := TClientDataSet.Create(nil);
    with _tmp do begin
  //fields  
      with FieldDefs.AddFieldDef do begin
        Name := 'GoodsID';
        DataType := ftInteger;
      end;
      with FieldDefs.AddFieldDef do begin
        Name := 'BarCode';
        DataType := ftString;
      end;
      with FieldDefs.AddFieldDef do begin
        Name := 'Code';
        DataType := ftString;
      end;
      with FieldDefs.AddFieldDef do begin
        Name := 'Name';
        DataType := ftString;
      end;
      with FieldDefs.AddFieldDef do begin
        Name := 'Tax';
        DataType := ftInteger;
      end;
      with FieldDefs.AddFieldDef do begin
        Name := 'ChkInteger';
        DataType := ftBoolean;
      end;
      with FieldDefs.AddFieldDef do begin
        Name := 'Price';
        DataType := ftFloat;
      end;
      with FieldDefs.AddFieldDef do begin
        Name := 'EcrCode';
        DataType := ftInteger;
      end;
      with FieldDefs.AddFieldDef do begin
        Name := 'ZRep';
        DataType := ftInteger;
      end;
    end;
    _tmp.CreateDataSet;
    Result := _tmp;
    _tmp := nil;
  except
    on E: Exception do begin
      __EventLogger.LogError('500_TDataStream.__GoodsCasheCreate exception: '+e.Message);
      Result := nil;
    end;
  end;
end;

{$ifdef debug}
procedure ShowDebugGrid(_cds: TDataSet);
begin
    frmDbGrid:=TfrmDbGrid.Create(nil);
    frmDbGrid.ds.DataSet:=TDataSet(_cds);
    frmDbGrid.Caption:=TDataSet(_cds).Name;
    frmDbGrid.ShowModal;
    frmDbGrid.Free;
end;
{$endif}

function TDataStream.__OpenGoodsCashe(_DevEnum: PDevEnum): TClientDataSet;
var
  _tmp: TClientDataSet;
begin
  try
    if FileExists(__GoodsCashe+IntToStr(_DevEnum^.SerialNum)+__dbext) then begin
      _tmp := TClientDataSet.Create(nil);
      _tmp.LoadFromFile(__GoodsCashe+IntToStr(_DevEnum^.SerialNum)+__dbext);
      _tmp.AddIndex('idxMainFull', 'GoodsID;BarCode;Code;Name;Tax;ChkInteger;Price', [ixCaseInsensitive],'','',0);
      _tmp.AddIndex('IdxMainShort', 'GoodsID;Code;Name;Tax;ChkInteger;Price', [ixCaseInsensitive],'','',0);
{$ifdef debug}
//      if _tmp.RecordCount > 0 then
//        ShowDebugGrid(_tmp);
{$endif}
      _tmp.Last;
      _DevEnum^.LastEcrCode := _tmp.FieldByName('EcrCode').AsInteger;
    end
    else begin
      _tmp := __GoodsCasheCreate;
      _tmp.AddIndex('idxMainFull', 'GoodsID;BarCode;Code;Name;Tax;ChkInteger;Price', [ixCaseInsensitive],'','',0);
      _tmp.AddIndex('IdxMainShort', 'GoodsID;Code;Name;Tax;ChkInteger;Price', [ixCaseInsensitive],'','',0);
      _DevEnum^.LastEcrCode := __LastEcrCode;
    end;
    _tmp.LogChanges:=False;
    Result := _tmp;
    _tmp := nil;
  except
    on E: Exception do begin
      __EventLogger.LogError('500_TDataStream.__OpenGoodsCashe exception: '+e.Message);
      Result := nil;
    end;
  end;
end;

procedure TDataStream.__CreateDevEnum(_DevArray: TDevArray);
var 
  _DevEnum: PDevEnum;
  _i: Integer;
  _CountDev: Integer;
begin
  try
    _CountDev := Length(_DevArray);
    __DevEnum := nil;
    if _CountDev > 0 then
    begin
      for _i:=0 to _CountDev-1 do 
      begin
        GetMem(_DevEnum, SizeOf(TDevEnum));
        FillChar(_DevEnum^,SizeOf(TDevEnum),$00);
        _DevEnum^.SerialNum := Integer(_DevArray[_i,0]);
        _DevEnum^.DevNum := Integer(_DevArray[_i,1]);
        _DevEnum^.Depart := Integer(_DevArray[_i,2]);
        _DevEnum^.Off :=  Integer(_DevArray[_i,3]);
        if _DevEnum^.Off <> __Off then begin 
          _DevEnum^.CheckState := TCheckState.Create(__TmpDir);
          TCheckState(_DevEnum^.CheckState).__SaveServiceCheck := __SaveServiceCheck;
          TCheckState(_DevEnum^.CheckState).__WriteProtocol := __WriteProtocol;
          _DevEnum^.GoodsCash := __OpenGoodsCashe(_DevEnum);
          _DevEnum^.Log := TLog.Create(__ProtocolDir+IntToStr(_DevArray[_i,0]));
        end
        else begin
          _DevEnum^.CheckState := nil;
          _DevEnum^.GoodsCash := nil;
          _DevEnum^.Log := nil;
        end;
        if ( assigned( __DevEnum ) ) then 
          _DevEnum^.Next := __DevEnum^.Next
        else __DevEnum := _DevEnum;
        __DevEnum^.Next := _DevEnum;
      end;
    end;
  finally
{$ifdef CS}
    LeaveCriticalSection(__CSDev);
{$else}  
    SetEvent(__EvHDev);
{$endif}  
  end;
end;

procedure TDataStream.__FreeDevEnum;
var 
  _tmp: PDevEnum;
begin
  try
    if assigned(__DevEnum) then begin
      while true do begin
        _tmp := __DevEnum^.Next;
        if _tmp = __DevEnum then begin
          if assigned(__DevEnum^.CheckState) then begin
            FreeAndNil(TCheckState(__DevEnum^.CheckState));
          end;
          if assigned(__DevEnum^.GoodsCash) then begin
            TClientDataSet(__DevEnum^.GoodsCash).SaveToFile(__GoodsCashe+IntToStr(__DevEnum^.SerialNum)+__dbext);
            TClientDataSet(__DevEnum^.GoodsCash).Close;
            FreeAndNil(TClientDataSet(__DevEnum^.GoodsCash));
            if assigned(TLog(__DevEnum^.Log)) then
              FreeAndNil(TLog(__DevEnum^.Log));
          end;
          FreeMem(__DevEnum);
          __DevEnum := nil;
          break;
        end
        else begin
          __DevEnum^.Next := _tmp^.Next;
          if assigned(_tmp^.CheckState) then begin
            FreeAndNil(TCheckState(_tmp^.CheckState));
          end;
          if assigned(_tmp^.GoodsCash) then begin
            TClientDataSet(_tmp^.GoodsCash).SaveToFile(__GoodsCashe+IntToStr(_tmp^.SerialNum)+__dbext);
            TClientDataSet(_tmp^.GoodsCash).Close;
            FreeAndNil(TClientDataSet(_tmp^.GoodsCash));
          end;
          FreeMem(_tmp);
        end;
      end;
    end;
  finally
  end;
end;

procedure TDataStream.Initialize;
var
  _msg: TMsg;
  _DevArray: TDevArray;
  _i: Integer;
begin

  __DBObj := TSecondDBObj.Create;

  __Goods := __DBObj.GetGoods;
  __BarCodes := __DBObj.GetBarCodes;
  __DepPrice := __DBObj.GetDepPrice;
  __Ecrs := __DBObj.GetEcrs('PORTID = '+ IntToStr(__PortID) );

{$ifdef CS}
  InitializeCriticalSection(__CS);
  InitializeCriticalSection(__CSDev);
  EnterCriticalSection(__CSDev);
{$else}  
  __EvH := CreateEvent(nil,false,true,nil);
  __EvHDev := CreateEvent(nil,false,false,nil);
{$endif}  

  with __Ecrs do begin
    SetLength(_DevArray, RecordCount);
    __Ecrs.First;
    for _i:= 0 to __Ecrs.RecordCount - 1 do
    begin
      _DevArray[_i,0] := Cardinal(FieldByName('SERNUMBER').AsInteger);
      _DevArray[_i,1] := Cardinal(FieldByName('NUMBER').AsInteger);
      _DevArray[_i,2] := Cardinal(FieldByName('DEPARTID').AsInteger);
      _DevArray[_i,3] := Cardinal(FieldByName('OFF').AsInteger);
      __Ecrs.Next;
    end;
  end;

  if __GetParams then begin
    if Length(__PQDLibraryName)>0 then begin
      __HParseQueryDiscLiblary := LoadLibrary(PChar(Copy(ParamStr(0), 1, LastDelimiter(PathDelimiter, ParamStr(0)))+PathDelimiter+__PQDLibraryName+__Libraryext));
      if (__HParseQueryDiscLiblary <> INVALID_HANDLE_VALUE) and (__HParseQueryDiscLiblary <> 0) then begin
        @___InitParseQueryDisc := GetProcAddress(__HParseQueryDiscLiblary, PChar(__InitParseQueryDisc__));
        @___ParseQueryDisc := GetProcAddress(__HParseQueryDiscLiblary, PChar(__ParseQueryDisc__));
      end;
      if assigned(___InitParseQueryDisc) then ___InitParseQueryDisc();
    end;

    if Length(__PBLibraryName)>0 then begin
      __HParseBarLibrary := LoadLibrary(PChar(Copy(ParamStr(0), 1, LastDelimiter(PathDelimiter, ParamStr(0)))+PathDelimiter+__PBLibraryName+__Libraryext));
      if (__HParseBarLibrary <> INVALID_HANDLE_VALUE) and (__HParseBarLibrary <> 0) then begin
        @___InitParseBar := GetProcAddress(__HParseBarLibrary, PChar(__InitParseBar__));
        @___ParseBar := GetProcAddress(__HParseBarLibrary, PChar(__ParseBar__));
      end;
      if assigned(___InitParseBar) then ___InitParseBar(__HParseBarLibrary);
    end;
  end;
  
  if ( assigned(__ConnectionStream) ) then
  begin
    __CreateDevEnum(_DevArray);
    __CheckTmpCDS;
    __ConnectionStream.DevEnum := __DevEnum;
{$ifdef CS}    
    __ConnectionStream.CS := __CSDev ;
{$else}    
    __ConnectionStream.Ev := __EvHDev ;
{$endif}
    __ConnectionStream.__WriteProtocol := __WriteProtocol;
    __ConnectionStream.__WriteFullProtocol := __WriteFullProtocol;
    __ConnectionStream.__RejectNoAnswer := __RejectNoAnswer;
    __ConnectionStream.__NoRejectIfNull := __NoRejectIfNull;
    __ConnectionStream.__SendNullIfReadError := __SendNullIfReadError;

    PeekMessage(_msg, 0, WM_USER, WM_USER, PM_NOREMOVE);
    __ConnectionStream.Resume;
  end;
end;

procedure TDataStream.ProcessPacket(_P: Pointer; _OpData: POpData);
var
  _opType: Byte;
begin
  try
    try
      _opType := Byte(POpData(_OpData)^.__opType);
      case _opType of
        opSaleArt: __SaleArt(_P, _OpData^.__DevEnum);
        opPayment: __Payment(_P, _OpData^.__DevEnum);
        opAnnul: __Annul(_P, _OpData^.__DevEnum);
        opQeryDisc: __QueryDisc(_P, _OpData^.__DevEnum);
        opSaleCode: __SaleCode(_P, _OpData^.__DevEnum);
        opDiscount: __Discount(_P, _OpData^.__DevEnum);
        opSaleBar: __SaleBar(_P, _OpData^.__DevEnum);
        opQueryKey: __QueryKey(_P, _OpData^.__DevEnum);
        opRejectSale: __RejectLastOperation(_P, _OpData^.__DevEnum);
        opRejectSaleCode: __RejectSaleCode(_P, _OpData^.__DevEnum);
        opRejectSaleBar: __RejectSaleBar(_P, _OpData^.__DevEnum);
      end;
    except
      on e: Exception do begin
        __EventLogger.LogError('500_TDataStream.ProcessPacket exception: '+e.Message);
      end;
    end;
  finally
    FreeMem(_OpData, SizeOf(TOpData));
  end;
end;

procedure TDataStream.__RefreshGoodsCashe(_case: Integer);
var
  _cds: TClientDataSet;
{$ifndef CS}
  _TimeOut: Cardinal;
{$endif}  
begin
  try
{$ifdef CS}
    EnterCriticalSection(__CS);
{$else}  
    if __TimeOut = 0 then
      _TimeOut := INFINITE
    else _TimeOut := 2000;
    if WaitForSingleObject(__EvH, _TimeOut) = WAIT_OBJECT_0 then begin
{$endif}  
      try
        case ( _case ) of
          __cBarCodesChange: begin
            _cds := __DBObj.GetBarCodes;
            __ProcEventsAlert(_cds, _case);
          end;
          __cDepPriceChange: begin
            _cds := __DBObj.GetDepPrice;
            __ProcEventsAlert(_cds, _case);
          end;
        else 
          begin
            _cds := __DBObj.GetBarCodes;
            __ProcEventsAlert(_cds, __cBarCodesChange);
            _cds := __DBObj.GetDepPrice;                          
            __ProcEventsAlert(_cds, __cDepPriceChange);
            _cds := __DBObj.GetGoods;
            __ProcEventsAlert(_cds, __cGoodsChange);
          end;
        end;
      except
        on e: Exception do begin
          __EventLogger.LogError('500_TDataStream.__RefreshGoodsCashe exception: '+e.Message);
        end;
      end;
{$ifndef CS}
    end
    else
      __EventLogger.LogError('500_TDataStream.__RefreshGoodsCashe __EvH timeout');
{$endif}  
  finally
{$ifdef CS}
    LeaveCriticalSection(__CS);
{$else}  
    SetEvent(__EvH);
{$endif}  
  end;
end;

procedure TDataStream.Run;
var
	_msg: TMsg;
	_WaitTime: DWord;
  _Event: THandle;
  _ReceiveSuccess: Boolean;
begin
  try
{$ifdef Process_Priority}
		Windows.SetThreadPriority(GetCurrentThread(),THREAD_PRIORITY_ABOVE_NORMAL);
{$endif}
    if __TimeOut = 0 then
      _WaitTime := INFINITE else
      _WaitTime := 60000;
    _Event := CreateEvent(nil, true, false, nil);
    while not __Terminated do
    try
      case MsgWaitForMultipleObjects(1, _Event, False, _WaitTime, QS_ALLINPUT) of
        WAIT_OBJECT_0 + 1:
          while PeekMessage(_msg, 0, 0, 0, PM_REMOVE) do begin
//            if (_msg.hwnd = 0) then
//              __EventLogger.LogInformation('500_TDataStream.Run _msg.hwnd: '+IntToStr(_msg.hwnd)+'; _msg.message: '+IntToStr(_msg.message)+'; _msg.wParam: '+IntToStr(_msg.wParam));
            if (_msg.hwnd = 0) then
              case _msg.message of
                THREAD_REFRESH: begin
                  __RefreshGoodsCashe(_msg.wParam);
                end;
                THREAD_BREAK:	begin
                  __Terminate;
                end;
                THREAD_BREAK_CONNECT: begin
                  __ConnectionStream.WaitForExit; 
                  __Terminated := True;
                  SetEvent(_Event);
                end;
              else DispatchMessage(_msg);
              end
            else DispatchMessage(_msg);
          end;
        WAIT_OBJECT_0: begin
          ResetEvent(_Event);
          Sleep(1);
        end;
        else Sleep(1);
//        WAIT_TIMEOUT: begin
//          while PeekMessage(_msg, 0, 0, 0, PM_REMOVE) do
//            DispatchMessage(_msg);
//        end;
      end;
    except
      on e: Exception do begin
        __EventLogger.LogError('500_TDataStream.Run exception: '+e.Message);
        __Terminated := True;
      end;
    end;
  finally
    CloseHandle(_Event);
{$ifdef CS}
    DeleteCriticalSection(__CS);
    DeleteCriticalSection(__CSDev);
{$else}
    WaitForSingleObject(__EvH, __EvWaitCloseTimeOut);    
    CloseHandle(__EvH);
    WaitForSingleObject(__EvHDev, __EvWaitCloseTimeOut);    
    CloseHandle(__EvHDev);
{$endif}
  end;  
end;

constructor TDataStream.Create;
begin
	inherited Create;
  __Goods := nil;
  __BarCodes := nil;
  __DepPrice := nil;
  __Ecrs := nil;
  __ConnectionStream := nil;
  __Terminated := False;
  ___InitParseQueryDisc := nil;
  ___InitParseBar := nil;
  ___ParseQueryDisc := nil;
  ___ParseBar := nil;
  __TimeOut := __NOINFINITE;
  __HLibrary := 0;
  __HParseQueryDiscLiblary := 0;
  __HParseBarLibrary := 0;
  __ConnectionStream := TConnectionStream.Create;
  __EventLogger := TEventLogger.Create('500_CassSrv DataStream '+ IntToStr(Integer(Pointer(__ConnectionStream))));
  __SaveServiceCheck := __DefSaveServiceCheck;
  __WriteProtocol := __DefWriteProtocol;
  __WriteFullProtocol := __DefWriteFullProtocol;
  __RejectNoAnswer := __DefRejectNoAnswer;
  __NoRejectIfNull := __DefNoRejectIfNull;
  __SendNullIfReadError := __DefSendNullIfReadError;
end;

destructor TDataStream.Destroy;
begin
  __CloseStream;
	if (__HParseQueryDiscLiblary <> INVALID_HANDLE_VALUE) and (__HParseQueryDiscLiblary <> 0) then
	  FreeLibrary(__HParseQueryDiscLiblary); __HParseQueryDiscLiblary := 0;
	if (__HParseBarLibrary <> INVALID_HANDLE_VALUE) and (__HParseBarLibrary <> 0) then
	  FreeLibrary(__HParseBarLibrary); __HParseBarLibrary := 0;
  if ( assigned( __ConnectionStream ) and (__ConnectionStream is TConnectionStream) ) then 
    __ConnectionStream.Free;
  if ( assigned(__DevEnum) ) then  __FreeDevEnum;
  if ( assigned(__DBObj) ) then FreeAndNil( __DBObj );
  __EventLogger.Free;
	inherited;
end;

procedure TDataStream.Terminate;
begin
  PostThreadMessage(__StreamThID, THREAD_BREAK, 0, 0);
end;

function TDataStream.InitializeStream(_P: Pointer): BOOL;
var
  _Event: THandle;
begin
  Result := False;
  __StreamHandle := CreateThread( nil, 0, @DataStreamThreadProc, _P, CREATE_SUSPENDED, __StreamThID );
  Result := BOOL(__StreamHandle);
  if Result then begin
    __ConnectionStream.Port := __Port;
    __ConnectionStream.BaudNumber := __BaudNumber;
    if __ConnectionStream.InitializeStream( @__ConnectionStream, __StreamThID, @DatecsProc ) then
    begin
      __ConnectionStream.DataStream := _P;
      Result := True;
    end;
  end;
end;

procedure TDataStream.Resume;
begin
  ResumeThread(__StreamHandle);
end;

procedure TDataStream.__SaleArt(_P: Pointer; _DevEnum: PDevEnum);
var
  _S_Info: PInfo;
  _ProcStr: String;
  _ChkNum: Integer;
begin
// ��������� � ������� �������������������� ������.
  try
    _S_Info := PInfo(_P);
    _ProcStr := Trim(PChar(TBuffer(_S_Info^.BigReadBuffer)));
    try _ChkNum := StrToInt(StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleChkNum));
    except _ChkNum := 0; end;
    TCheckState(_DevEnum^.CheckState).AppendLast(_DevEnum, _ChkNum );
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__SaleArt exception: '+e.Message);
    end;
  end;
end;

procedure TDataStream.__Payment(_P: Pointer; _DevEnum: PDevEnum);
var
  _S_Info: PInfo;
  _tKnd,
  _ProcStr: String;
  _ChkNum: Integer;
  _Sum,
  _TotalSum: Currency;
begin
// ��������� �� ������.
  try
    _S_Info := PInfo(_P);
    _ProcStr := Trim(PChar(TBuffer(_S_Info^.BigReadBuffer)));
    _tKnd := StrFunc.ExtractWord(_ProcStr, DlmField, __posPaytKind);
    if Length(_tKnd) = 0 then _tKnd := __kndPayCash
    else if (_tKnd = __kndPayCard) then _tKnd := __kndPayCredit;
    try _ChkNum := StrToInt(StrFunc.ExtractWord(_ProcStr, DlmField, __posPayChkNum));
    except _ChkNum := 0; end;
    try _TotalSum := StrToCurr(StrFunc.ExtractWord(_ProcStr, DlmField, __posPaySumTotal));
    except _TotalSum := 0.00; end;
    try _Sum := StrToCurr(StrFunc.ExtractWord(_ProcStr, DlmField, __posPaySum));
    except _Sum := 0.00; end;
    if (Trunc(Abs(_Sum)*10000+0.5)/100 = 0) or (Abs(_Sum) > Abs(_TotalSum)) then _Sum := _TotalSum;
    TCheckState(_DevEnum^.CheckState).Payment( __MainTHId, _DevEnum, _tKnd, _ChkNum, _TotalSum, _Sum );
    if __Terminated then _DevEnum^.Off := __Off;
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__Payment exception: '+e.Message);
    end;
  end;
end;

procedure TDataStream.__Annul(_P: Pointer; _DevEnum: PDevEnum);
var
  _S_Info: PInfo;
  _ProcStr: String;
  _ChkNum: Integer;
begin
// ������ �� ������������� ����� ����.
  try
    _S_Info := PInfo(_P);
    _ProcStr := Trim(PChar(TBuffer(_S_Info^.BigReadBuffer)));
    try _ChkNum := StrToInt(StrFunc.ExtractWord(_ProcStr, DlmField, __posAnnulChkNum));
    except _ChkNum := 0; end;
    _ProcStr := #10+';;;;;'+#13;
    _S_Info^.BigWriteCount := Length(_ProcStr);
    __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
    TCheckState(_DevEnum^.CheckState).RegisterAnnul(_DevEnum, _ChkNum);
    if __Terminated then _DevEnum^.Off := __Off;
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__Annul exception: '+e.Message);
    end;
  end;
end;

procedure TDataStream.ConfirmAnnul(_DevEnum: PDevEnum);
begin
// ������������� �� ������������� ����� ����.
  try
    TCheckState(_DevEnum^.CheckState).ConfirmAnnul(__MainTHId, _DevEnum);
    if __Terminated then _DevEnum^.Off := __Off;
  except
    on e: Exception do begin
      __EventLogger.LogError('550_TDataStream.__ConfirmAnnul exception: '+e.Message);
    end;
  end;
end;

function TDataStream.__ParseQueryDisc( _ChkNum: Integer; _Perc, _BSum: Double; var _tDKnd: Integer; _DevEnum: PDevEnum ): Double;
begin
//��������� ������� ������/��������
  Result := 0.00;
  try
{$ifdef drvdll}  
    if assigned(___ParseQueryDisc) then Result := ___ParseQueryDisc(_ChkNum, _Perc, _BSum, _tDKnd);
{$else}  
    Result := 10.00;
    if _Perc < 0 then begin
      if _tDKnd in [ __DiscOnLastPerc, __DiscPerc ] then
        _tDKnd := ___DiscPerc
      else
        _tDKnd := ___DiscSum;
    end
    else begin
      if _tDKnd in [ __DiscOnLastPerc, __DiscPerc ] then
        _tDKnd := ___AddPerc
      else
        _tDKnd := ___AddSum;
    end;
{$endif}
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__ParseQueryDisc exception: '+e.Message);
    end;
  end;
end;

procedure TDataStream.__QueryDisc(_P: Pointer; _DevEnum: PDevEnum);
var
  _S_Info: PInfo;
  _ProcStr: String;
  _Val: String;
  _Perc: Double;
  _BSum: Double; 
  _tDKind: Integer;
  _ChkNum: Integer;
begin
//��������� � ������/��������.
  try
    _S_Info := PInfo(_P);
    _ProcStr := Trim(PChar(TBuffer(_S_Info^.BigReadBuffer)));
    try _tDKind :=  StrToInt(StrFunc.ExtractWord(_ProcStr, DlmField, __postDiscountKind));
    except _tDKind := 0; end;
    try _ChkNum := StrToInt(StrFunc.ExtractWord(_ProcStr, DlmField, __posQueryDiscChkNum));
    except _ChkNum := 0; end;
    try _Perc := StrToFloat(StrFunc.ExtractWord(_ProcStr, DlmField, __postValueDiscount));
    except _Perc := 0; end;
    try _BSum := StrToFloat(StrFunc.ExtractWord(_ProcStr, DlmField, __posSumBefDisc));
    except _BSum := 0; end;
    _Val := FloatToStr(__ParseQueryDisc(_ChkNum, _Perc, _BSum, _tDKind, _DevEnum));
    case Length(StrFunc.ExtractWord( _Val, _DS, 2)) of
      0: _Val := _Val + '.00';
      1: _Val := _Val + '0';
    end;
    _ProcStr := #10+'C;'+IntToStr(_tDKind)+';'+_Val+';;;;'+#13;
    _S_Info^.BigWriteCount := Length(_ProcStr);
    __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__QueryDisc excepiton: '+e.Message);
      _ProcStr := #10+'C;'+IntToStr(_tDKind)+';0;;;;'+#13;
      _S_Info^.BigWriteCount := Length(_ProcStr);
      __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
    end;
  end;
end;

procedure TDataStream.__SaleCode(_P: Pointer; _DevEnum: PDevEnum);
var
  _S_Info: PInfo;
  _ProcStr: String;
  _GPrm: TGoodsParam;
  _Row,
  _ChkNum: Integer;
begin
// ������ �� ������� ������ �� ����.
  try
    _S_Info := PInfo(_P);
    _ProcStr := Trim(PChar(TBuffer(_S_Info^.BigReadBuffer)));
    _GPrm.isBarCode := False;
    _GPrm.Count := StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleCount);
    _GPrm.Code := StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleCode);
    try _ChkNum := StrToInt(StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleChkNum));
    except _ChkNum := 0; end;
    try _Row := StrToInt(StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleRow));
    except _Row := 0; end;
    if __GetGoodsParam( _GPrm, _DevEnum ) then begin
      with _GPrm do
        if TCheckState(_DevEnum^.CheckState).SaveSale(_DevEnum, _GPrm, _ChkNum, _Row) then begin
          _ProcStr := #10+EcrCode+';'+Name+';'+Price+';'+Count+';1;1;'+Tax+';0;0;;;'+#13;
          _S_Info^.BigWriteCount := Length(_ProcStr);
          __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
        end        
        else begin
          _ProcStr := #10+';;;;;;;;;;;'+#13;
          _S_Info^.BigWriteCount := Length(_ProcStr);
          __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
        end;
    end
    else begin
      TCheckState(_DevEnum^.CheckState).__tReject := False;
      _ProcStr := #10+';;;;;;;;;;;'+#13;
      _S_Info^.BigWriteCount := Length(_ProcStr);
      __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
    end;
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__SaleCode exception: '+e.Message);
      TCheckState(_DevEnum^.CheckState).__tReject := False;
      _ProcStr := #10+';;;;;;;;;;;'+#13;
      _S_Info^.BigWriteCount := Length(_ProcStr);
      __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
    end;
  end;
end;

procedure TDataStream.__Discount(_P: Pointer; _DevEnum: PDevEnum);
var
  _S_Info: PInfo;
  _ProcStr: String;
  _BSum, _ASum, _Val: Double; 
  _tDKind: Integer;
  _ChkNum: Integer;
begin
//��������� � ������/��������.
  try
    _S_Info := PInfo(_P);
    _ProcStr := Trim(PChar(TBuffer(_S_Info^.BigReadBuffer)));
    try _tDKind :=  StrToInt(StrFunc.ExtractWord(_ProcStr, DlmField, __postDiscountKind));
    except _tDKind := 0; end;
    try _ChkNum := StrToInt(StrFunc.ExtractWord(_ProcStr, DlmField, __posDiscChkNum));
    except _ChkNum := 0; end;
    try _BSum := StrToFloat(StrFunc.ExtractWord(_ProcStr, DlmField, __posSumBefDisc));
    except _BSum := 0; end;
    try _ASum := StrToFloat(StrFunc.ExtractWord(_ProcStr, DlmField, __posSumAftDisc));
    except _ASum := 0; end;
    try _Val := StrToFloat(StrFunc.ExtractWord(_ProcStr, DlmField, __postValueDiscount));
    except _Val := 0; end;
    TCheckState(_DevEnum^.CheckState).RegisterDiscount(_DevEnum, _ChkNum, _BSum, _ASum, _Val, _tDKind);
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__Discount exception: '+e.Message);
    end;
  end;
end;

function TDataStream.__ParseBar( var _P: TGoodsParam; _DevEnum: PDevEnum ): Boolean;
var
  _IdGoods: Integer;
  _F_Code, 
  _F_Name, _F_GID,
  _F_Price, _F_TaxID: TField;
{$ifndef CS}
  _TimeOut: Integer;
{$endif}  
  
begin
  Result := False;
  try
{$ifdef CS}
    EnterCriticalSection(__CS);
{$else}  
    if __TimeOut = 0 then
      _TimeOut := INFINITE
    else _TimeOut := 2000;
    if WaitForSingleObject(__EvH, _TimeOut) = WAIT_OBJECT_0 then begin
{$endif}  
      try
        if assigned(___ParseBar) then Result := ___ParseBar(_P);
        if Result then begin
          _F_Code := __Goods.FieldByName('CODE');
          _F_Name := __Goods.FieldByName('ECRNAME');
          _F_Price := __DepPrice.FieldByName('PRICE');
          _F_TaxID := __DepPrice.FieldByName('TAXID');
          _F_GID := __Goods.FieldByName('ID');
          __Goods.IndexName := 'Idx_CODE';
          __Goods.EditKey;
          __Goods.FieldByName('CODE').AsInteger := StrToInt(_P.Code);
          if __Goods.GotoKey then begin
            _IdGoods := _F_GID.AsInteger;
            _P.Name := _P.Code+'.'+_F_Name.AsString;
            if __Goods.FieldByName('CHKINTEGER').AsString = 'F' then _P.Dividable := True
            else _P.Dividable := False;
            __DepPrice.IndexName := 'Idx_GOOD_DEPART';
            __DepPrice.EditKey;
            __DepPrice.FieldByName('GOODSID').AsInteger := _IdGoods;
            __DepPrice.FieldByName('DEPARTID').AsInteger := _DevEnum^.Depart;
            _P.GoodsID := IntToStr(_IdGoods);
            if __DepPrice.GotoKey then begin
              _P.OriginalPrice := Trunc(_F_Price.AsCurrency * 100+0.5)/100;
              if (Trunc(_P.Zoom * 10000+0.5)/100 > 0) then begin
                _P.Price := CurrToStr(Trunc(_P.Zoom * _F_Price.AsCurrency * 100+0.5)/100);
              end
              else
                _P.Price := _F_Price.AsString;
              case Length(StrFunc.ExtractWord( _P.Price, _DS, 2)) of
                0: _P.Price := _P.Price + '.00';
                1: _P.Price := _P.Price + '0';
              end;
              _P.Tax := _F_TaxID.AsString;
              if Length( _P.Tax ) = 0 then _P.Tax := '0';
              if Length(_P.Name) < 18 then 
                _P.Name := StrUtils.LeftStr(_P.Name,18)
              else
                _P.Name := Copy(_P.Name, 1, 18);
              _P.Name := WinStrToDatecs(_P.Name);
              Result := (((not _P.Dividable) and ( Round(_P.Zoom) = _P.Zoom)) or _P.Dividable);
              if Result and _P.isBarCode then
                with TClientDataSet(_DevEnum^.GoodsCash) do begin 
                  try
                    IndexName := 'idxMainFull';
                    EditKey;
                    FieldByName('BarCode').AsString := _P.BarCode;
                    FieldByName('Code').AsString := _P.Code;
                    FieldByName('GoodsID').AsString := _P.GoodsID;
                    FieldByName('Name').AsString := _P.Name;
                    FieldByName('Price').AsCurrency := StrToCurr(_P.Price);
                    FieldByName('Tax').AsInteger := StrToInt(_P.Tax);
                    FieldByName('ChkInteger').AsBoolean := not _P.Dividable;
                    if GotoKey then begin
                      _P.EcrCode := FieldByName('EcrCode').AsString;
                    end
                    else begin
                      try
                        Append;
                        FieldByName('BarCode').AsString := _P.BarCode;
                        FieldByName('Code').AsString := _P.Code;
                        FieldByName('GoodsID').AsString := _P.GoodsID;
                        FieldByName('Name').AsString := _P.Name;
                        FieldByName('Tax').AsInteger := StrToInt(_P.Tax);
                        FieldByName('Price').AsCurrency := StrToCurr(_P.Price);
                        FieldByName('ChkInteger').AsBoolean := not _P.Dividable;
                        _DevEnum^.LastEcrCode := _DevEnum^.LastEcrCode + 1;
                        FieldByName('EcrCode').AsInteger := _DevEnum^.LastEcrCode;
                        Post;
                        _P.EcrCode := FieldByName('EcrCode').AsString;
                        try
                          SaveToFile(__GoodsCashe+IntToStr(_DevEnum^.SerialNum)+__dbext);
                        finally
                        end;
                      except
                        on E: Exception do begin
                          __EventLogger.LogError('500_TDataStream.__ParseBar exception 1: '+E.Message);
                          Cancel;
                        end;
                      end;
                    end;
                  except
                    on E: Exception do begin
                      __EventLogger.LogError('500_TDataStream.__ParseBar exception 2: '+E.Message);
                      Result := False;
                    end;
                  end;
                end; 
            end
            else Result := False;
          end;
        end;
      except
        on e: Exception do begin
          __EventLogger.LogError('500_TDataStream.__ParseBar exception: '+e.Message);
        end;
      end;
{$ifndef CS}
    end
    else
      __EventLogger.LogError('500_TDataStream.__ParseBar __EvH timeout');
{$endif}                      
  finally
{$ifdef CS}
    LeaveCriticalSection(__CS);
{$else}  
    SetEvent(__EvH);
{$endif}  
  end;
end;

procedure TDataStream.__SaleBar(_P: Pointer; _DevEnum: PDevEnum);
var
  _S_Info: PInfo;
  _ProcStr: String;
  _GPrm: TGoodsParam;
  _Row,
  _ChkNum: Integer;
begin
// ������ �� ������� ������ �� ���������.
  try
    _S_Info := PInfo(_P);
    _ProcStr := Trim(PChar(TBuffer(_S_Info^.BigReadBuffer)));
    _GPrm.isBarCode := True;
    _GPrm.Count := StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleCount);
    _GPrm.BarCode := StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleCode);
    try _ChkNum := StrToInt(StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleChkNum));
    except _ChkNum := 0; end;
    try _Row := StrToInt(StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleRow));
    except _Row := 0; end;
    if __GetGoodsParam( _GPrm, _DevEnum ) then begin
      with _GPrm do begin
        _ProcStr := #10+EcrCode+';'+Name+';';
        _ProcStr := _ProcStr + Price + ';'+Count+';1;1;'+Tax+';0;0;;;'+#13;
        _S_Info^.BigWriteCount := Length(_ProcStr);
        __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
        Price := CurrToStr(OriginalPrice); 
        if (StrToFloat(Count) > 0) then
          Count := FloatToStr(Trunc(StrToFloat(Count)*Zoom*10000+0.5)/10000)
        else
          Count := FloatToStr(Trunc(StrToFloat(Count)*Zoom*10000-0.5)/10000);
        if not TCheckState(_DevEnum^.CheckState).SaveSale(_DevEnum, _GPrm, _ChkNum, _Row) then begin
          _ProcStr := #10+';;;;;;;;;;;'+#13;
          _S_Info^.BigWriteCount := Length(_ProcStr);
          __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
        end;
      end;
    end
    else begin
      if __ParseBar(_GPrm, _DevEnum) then begin
        with _GPrm do begin
          _ProcStr := #10+EcrCode+';'+Name+';';
          _ProcStr := _ProcStr + Price + ';'+Count+';1;1;'+Tax+';0;0;;;'+#13;
          _S_Info^.BigWriteCount := Length(_ProcStr);
          __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
          Price := CurrToStr(OriginalPrice); 
          if (StrToFloat(Count) > 0) then
            Count := FloatToStr(Trunc(StrToFloat(Count)*Zoom*10000+0.5)/10000)
          else
            Count := FloatToStr(Trunc(StrToFloat(Count)*Zoom*10000-0.5)/10000);
          if not TCheckState(_DevEnum^.CheckState).SaveSale(_DevEnum, _GPrm, _ChkNum, _Row) then begin
            _ProcStr := #10+';;;;;;;;;;;'+#13;
            _S_Info^.BigWriteCount := Length(_ProcStr);
            __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
          end;
        end;
      end
      else begin
        TCheckState(_DevEnum^.CheckState).__tReject := False;
        _ProcStr := #10+';;;;;;;;;;;'+#13;
        _S_Info^.BigWriteCount := Length(_ProcStr);
        __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
      end;
    end;
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__SaleBar exception: '+e.Message);
      TCheckState(_DevEnum^.CheckState).__tReject := False;
      _ProcStr := #10+';;;;;;;;;;;'+#13;
      _S_Info^.BigWriteCount := Length(_ProcStr);
      __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
    end;
  end;
end;

function TDataStream.__ParseKey(_Key: String; _DevEnum: PDevEnum): String;
var
  TmpStr: String;
begin
// ��������� ������� �� �����
  try
    if CompareStr(_Key, __CLEANGOODSTABLE) = 0 then begin  
      if FileExists(__GoodsCashe+IntToStr(_DevEnum^.SerialNum)+__dbext) then 
        DeleteFile(__GoodsCashe+IntToStr(_DevEnum^.SerialNum)+__dbext);
      _DevEnum^.GoodsCash := __OpenGoodsCashe(_DevEnum);
      TmpStr := ';'+  __ANSWERCLEANGOODS1 +';'+__ANSWERCLEANGOODS2+';;;';
      Result := #10+WinStrToDatecs(TmpStr)+#13;
    end
    else Result := #10+';;;;;'+#13;
  except
    on e: Exception do begin
      __EventLogger.LogError('TDataStream.__ParseKey excepion: '+e.Message);
      Result := #10+';;;;;'+#13;
    end;
  end;
end;

procedure TDataStream.__QueryKey(_P: Pointer; _DevEnum: PDevEnum);
var
  _S_Info: PInfo;
  _ProcStr: String;
  _Key: String;
begin
// ������ �� �����.
  try
    _S_Info := PInfo(_P);
    _ProcStr := Trim(PChar(TBuffer(_S_Info^.BigReadBuffer)));
    _Key := StrFunc.ExtractWord(_ProcStr, DlmField, __posQueryKey);
    _ProcStr := __ParseKey(_Key, _DevEnum);
    _S_Info^.BigWriteCount := Length(_ProcStr);
    __move(_ProcStr, _S_Info^.BigWriteBuffer, _S_Info^.BigWriteCount);
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__QueryKey exception: '+e.Message);
    end;
  end;
end;

procedure TDataStream.__RejectSaleCode(_P: Pointer; _DevEnum: PDevEnum);
var
  _S_Info: PInfo;
  _ProcStr: String;
  _GPrm: TGoodsParam;
begin
// ����� �� ������� ������ ����� ������ �� ������ �������.
  try
    _S_Info := PInfo(_P);
    _ProcStr := Trim(PChar(TBuffer(_S_Info^.BigReadBuffer)));
    _GPrm.isBarCode := False;
    _GPrm.Code := StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleCode);
    _GPrm.Count := StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleCount);
    if __GetGoodsParam( _GPrm, _DevEnum ) then begin
      TCheckState(_DevEnum^.CheckState).RejectSaleCode(_DevEnum, _GPrm);
    end;
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__RejectSaleCode exception: '+e.Message);
    end;
  end;
end;

procedure TDataStream.__RejectSaleBar(_P: Pointer; _DevEnum: PDevEnum);
var
  _S_Info: PInfo;
  _ProcStr: String;
  _GPrm: TGoodsParam;
begin
// ����� �� ������� ������ ����� ������ �� ������ �������.
  try
    _S_Info := PInfo(_P);
    _ProcStr := Trim(PChar(TBuffer(_S_Info^.BigReadBuffer)));
    _GPrm.isBarCode := True;
    _GPrm.BarCode := StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleCode);
    _GPrm.Code := StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleCode);
    _GPrm.Count := StrFunc.ExtractWord(_ProcStr, DlmField, __posSaleCount);
    if __GetGoodsParam( _GPrm, _DevEnum ) then begin
      TCheckState(_DevEnum^.CheckState).RejectSaleCode(_DevEnum, _GPrm);
    end;
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__RejectSaleBar exception: '+e.Message);
    end;
  end;
end;

procedure TDataStream.__RejectLastOperation(_P: Pointer; _DevEnum: PDevEnum);
var
  _S_Info: PInfo;
begin
  try
    _S_Info := PInfo(_P);
    TCheckState(_DevEnum^.CheckState).RejectSale(_DevEnum);
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__RejectSale exception: '+e.Message);
    end;
  end;
end;

procedure TDataStream.__ProcEventsAlert( _cds: TClientDataSet; _case: Integer );
begin
  try
    case ( _case ) of
      __cBarCodesChange: begin
        if assigned( __BarCodes ) then FreeandNil( __BarCodes );
        __BarCodes := _cds;
      end;
      __cDepPriceChange: begin
        if assigned( __DepPrice ) then FreeandNil( __DepPrice );
        __DepPrice := _cds;
      end;
      else begin
        if assigned( __Goods ) then FreeandNil( __Goods );
        __Goods := _cds;
      end;
    end;
  finally
  end;
end;

function TDataStream.__GetParams: Boolean;
var
  _RegIniFileName: String;
  _K:              DWORD;
  _Def__TmpDir,
  _Def__Cashe,
  _Def__Protocol,
  _TempStr:        String;
{$ifdef drvdll}
  _FailNameLen:    Integer;
{$endif}  
begin
  Result := True;
  try
{$ifdef drvdll}
	  if (__HLibrary <> INVALID_HANDLE_VALUE) and (__HLibrary <> 0) then begin
      SetLength(_TempStr, LenFileName);
      _FailNameLen := Integer(GetModuleFileName(__HLibrary, PChar(_TempStr), DWORD(LenFileName)));
      if BOOL(_FailNameLen) then begin
        SetLength(_TempStr, LenFileName);
        _RegIniFileName := Copy(Trim(_TempStr), 1, LastDelimiter('.', Trim(_TempStr)))+'ini';
{$else}        
        _RegIniFileName := Copy(ParamStr(0), 1, LastDelimiter(PathDelimiter, ParamStr(0))) + RegIniFileNameC;
{$endif}  

        SetLength(_TempStr, LenIniStr);
        FillChar(Pointer(_TempStr)^, LenIniStr, $0);
        _K:=GetPrivateProfileString(PChar(SectionLibrary), PChar(PQDLibraryNameK),
                                  PChar(Def__PQDLibraryName), PChar(_TempStr), LenIniStr,
                                  PChar(_RegIniFileName));

        __PQDLibraryName := Trim(_TempStr);
        if (__PQDLibraryName = '')or(not BOOL(_K)) then __PQDLibraryName := Def__PQDLibraryName;

        SetLength(_TempStr, LenIniStr);
        FillChar(Pointer(_TempStr)^, LenIniStr, $0);
        _K:=GetPrivateProfileString(PChar(SectionLibrary), PChar(PBLibraryNameK),
                                  PChar(Def__PBLibraryName), PChar(_TempStr), LenIniStr,
                                  PChar(_RegIniFileName));
        __PBLibraryName := Trim(_TempStr);
        if (__PBLibraryName = '')or(not BOOL(_K)) then __PBLibraryName := Def__PBLibraryName;

        _Def__TmpDir := Copy(ParamStr(0), 1, LastDelimiter(PathDelimiter, ParamStr(0)));
        if (LastDelimiter(PathDelimiter, _Def__TmpDir) <> Length(_Def__TmpDir)) then
          _Def__TmpDir := _Def__TmpDir + PathDelimiter;
        _Def__Cashe := _Def__TmpDir + 'Cashe';
        _Def__Protocol := _Def__TmpDir + 'Protocol';
        _Def__TmpDir := _Def__TmpDir + 'Tmp';

        SetLength(_TempStr, LenIniStr);
        FillChar(Pointer(_TempStr)^, LenIniStr, $0);
        _K:=GetPrivateProfileString(PChar(SectionLibrary), PChar(TmpDirK),
                                  PChar(_Def__TmpDir), PChar(_TempStr), LenIniStr,
                                  PChar(_RegIniFileName));
        __TmpDir := Trim(_TempStr);
        if (__TmpDir = '')or(not BOOL(_K)) then __TmpDir := _Def__TmpDir;
        if (LastDelimiter(PathDelimiter, __TmpDir) <> Length(__TmpDir)) then
          __TmpDir := __TmpDir + PathDelimiter;

        SetLength(_TempStr, LenIniStr);
        FillChar(Pointer(_TempStr)^, LenIniStr, $0);
        _K:=GetPrivateProfileString(PChar(SectionLibrary), PChar(GoodsCasheK),
                                  PChar(_Def__Cashe), PChar(_TempStr), LenIniStr,
                                  PChar(_RegIniFileName));
        __GoodsCashe := Trim(_TempStr);
        if (__GoodsCashe = '')or(not BOOL(_K)) then __GoodsCashe := _Def__Cashe;
        if (LastDelimiter(PathDelimiter, __GoodsCashe) <> Length(__GoodsCashe)) then
          __GoodsCashe := __GoodsCashe + PathDelimiter;
          
        SetLength(_TempStr, LenIniStr);
        FillChar(Pointer(_TempStr)^, LenIniStr, $0);
        _K:=GetPrivateProfileString(PChar(SectionLibrary), PChar(ProtocolDirK),
                                  PChar(_Def__Protocol), PChar(_TempStr), LenIniStr,
                                  PChar(_RegIniFileName));
        __ProtocolDir := Trim(_TempStr);
        if (__ProtocolDir = '')or(not BOOL(_K)) then __ProtocolDir := _Def__Protocol;
        if (LastDelimiter(PathDelimiter, __ProtocolDir) <> Length(__ProtocolDir)) then
          __ProtocolDir := __ProtocolDir + PathDelimiter;
          
        __SaveServiceCheck := GetPrivateProfileInt(PChar(SectionCommon), PChar(__kSaveServiceCheck),
                                       __DefSaveServiceCheck, PChar(_RegIniFileName));

        __WriteProtocol := GetPrivateProfileInt(PChar(SectionCommon), PChar(__kWriteProtocol),
                                       __DefWriteProtocol, PChar(_RegIniFileName));

        __WriteFullProtocol := GetPrivateProfileInt(PChar(SectionCommon), PChar(__kWriteFullProtocol),
                                       __DefWriteFullProtocol, PChar(_RegIniFileName));

        __RejectNoAnswer := GetPrivateProfileInt(PChar(SectionCommon), PChar(__kRejectNoAnswer),
                                       __DefRejectNoAnswer, PChar(_RegIniFileName));

        __NoRejectIfNull := GetPrivateProfileInt(PChar(SectionCommon), PChar(__kNoRejectIfNull),
                                       __DefNoRejectIfNull, PChar(_RegIniFileName));
                                       
        __SendNullIfReadError := GetPrivateProfileInt(PChar(SectionCommon), PChar(__kSendNullIfReadError),
                                       __DefSendNullIfReadError, PChar(_RegIniFileName));
{$ifdef drvdll}
      end;
    end;
{$endif}    
  except
    on e: Exception do begin
      __EventLogger.LogError('500_TDataStream.__GetParams exception: '+e.Message);
      Result := False;
    end;
  end;
end;

procedure TDataStream.__Terminate;
begin
  __ConnectionStream.Terminate;
end;

procedure TDataStream.WaitForExit;
begin
  if BOOL(__StreamHandle) then
    WaitForSingleObject(__StreamHandle, INFINITE);
end;

procedure TDataStream.Finalize;
begin
  if ( assigned(__DevEnum) ) then  __FreeDevEnum;
  if ( assigned(__DBObj) ) then FreeAndNil( __DBObj );
end;

initialization
  DecimalSeparator := _DS;

finalization  

end.



