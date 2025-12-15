unit DBAccessUnit;

interface

uses
    System.SysUtils
  , BaseDBAccessUnit
  , ParamsExtUnit
  , PlayListUnit
  ;

type
  TDBAccess = class (TBaseDBAccess)
  strict private
    procedure ShowExceptionMessage(
      const AMethod: String;
      const AE: Exception);
  public
    procedure CreateCatalogTable;
//    function CheckPath(const APath: String): Boolean;
    procedure InsertIntoCatalogTable(
      const APlayItemsList: TPlayItemsList);
    procedure DeleteFromCatalogTable(
      const APlayItemsList: TPlayItemsList);
    procedure SelectFromCatalogTable(
      const APath: String;
      const APlayItemsList: TPlayItemsList);
  end;

implementation

uses
    Data.DB
  , FMX.Dialogs
  , DBToolsUnit
  , DBExceptionContainerUnit
  ;

{ TDBAccess }

procedure TDBAccess.ShowExceptionMessage(
  const AMethod: String;
  const AE: Exception);
begin
  // Райзим эксепшн для вывода окна с сообщением, так универсальней
  raise Exception.Create(Concat(AMethod, ' -> ', AE.Message));
end;

procedure TDBAccess.CreateCatalogTable;
const
  METHOD = 'TDBAccess.CreateCatalogTable';
var
  Proc: TParamsProcRef;
begin
  Proc := (
    procedure(const AInParams: TParamsExt; const AOutParams: TParamsExt)
    var
      DBTools: TDBTools;
      SQLTemplateIdent: String;
      SQLTemplate: String;
    begin
      try
        SQLTemplateIdent := 'create_catalog_table';
        SQLTemplate := SQLTemplates.GetTemplate(SQLTemplateIdent);

        DBTools := TDBTools.Create(DBFileName);
        try
          DBTools.CreateQuery;
          DBTools.Query.ClearQuery;
          DBTools.Query.AddQuery(SQLTemplate);

          DBTools.StartTransaction;
          try
            DBTools.ExecuteQuery;
            DBTools.Commit;
          except
            DBTools.Rollback;
            raise;
          end;
        finally
          DBTools.FreeQuery;
          FreeAndNil(DBTools);
        end;

        AOutParams.Clear;
      except
        on e: Exception do
        begin
          raise TDBExceptionContainer.CreateExceptionContainer(e, METHOD);
        end;
      end;
    end
  );

  try
    DBAParamsFunc(Proc, nil, nil);
  except
    on e: Exception do
      ShowExceptionMessage(METHOD, e);
  end;
end;

//function TDBAccess.CheckPath(const APath: String): Boolean;
//const
//  METHOD = 'TDBAccess.CheckPath';
//var
//  Proc: TParamsProcRef;
//  InParams: TParamsExt;
//  OutParams: TParamsExt;
//begin
//  Result := false;
//
//  Proc := (
//    procedure(const AInParams: TParamsExt; const AOutParams: TParamsExt)
//    var
//      DBTools: TDBTools;
//      SQLTemplateIdent: String;
//      SQLTemplate: String;
//      QueryResult: TDBQuery;
//      CheckResult: Boolean;
//      Path: String;
//    begin
//      try
//        Path := InParams.AsStringByIdent['Path'];
//
//        SQLTemplateIdent := 'check_path';
//        SQLTemplate := SQLTemplates.GetTemplate(SQLTemplateIdent);
//
//        DBTools := TDBTools.Create(DBFileName);
//
//        try
//          DBTools.CreateQuery;
//          DBTools.Query.ClearQuery;
//          DBTools.Query.AddQuery(SQLTemplate);
//          DBTools.Query.AddParameterAsString(':path', Path);
//
//          QueryResult := DBTools.OpenQuery;
//          CheckResult := not QueryResult.IsEmpty;
//
//          DBTools.CloseQuery;
//        finally
//          DBTools.FreeQuery;
//          FreeAndNil(DBTools);
//        end;
//
//        AOutParams.Clear;
//        AOutParams.Add(CheckResult, 'CheckResult');
//      except
//        on e: Exception do
//        begin
//          raise TDBExceptionContainer.CreateExceptionContainer(e, METHOD);
//        end;
//      end;
//    end
//  );
//
//  try
//    InParams := TParamsExt.Create;
//    OutParams := TParamsExt.Create;
//    try
//      InParams.Add(APath, 'Path');
//
//      DBAParamsFunc(Proc, InParams, OutParams);
//
//      Result := OutParams.AsBooleanByIdent['CheckResult'];
//    finally
//      FreeAndNil(OutParams);
//      FreeAndNil(InParams);
//    end;
//  except
//    on e: Exception do
//      ShowExceptionMessage(METHOD, e);
//  end;
//end;

procedure TDBAccess.InsertIntoCatalogTable(const APlayItemsList: TPlayItemsList);
const
  METHOD = 'TDBAccess.InsertIntoCatalogTable';
var
  Proc: TParamsProcRef;
  Path: String;
  FileName: String;
  InParams: TParamsExt;
begin
  Proc := (
    procedure(const AInParams: TParamsExt; const AOutParams: TParamsExt)
    var
      DBTools: TDBTools;
      SQLTemplateIdent: String;
      SQLTemplate: String;
      PlayItem: TPlayItem;
      PlayItemsList: TPlayItemsList;
    begin
      try
        PlayItemsList := AInParams.AsPointerByIdent['PlayItemsList'];

        SQLTemplateIdent := 'insert_into_catalog_table';
        SQLTemplate := SQLTemplates.GetTemplate(SQLTemplateIdent);

        DBTools := TDBTools.Create(DBFileName);
        try
          DBTools.CreateQuery;
          for PlayItem in PlayItemsList do
          begin
            DBTools.Query.ClearQuery;
            DBTools.Query.AddQuery(SQLTemplate);

            Path := ExtractFilePath(PlayItem.Path);
            FileName := ExtractFileName(PlayItem.Path);

            DBTools.Query.AddParameterAsString(':path', Path);
            DBTools.Query.AddParameterAsString(':file_name', FileName);
            DBTools.Query.AddParameterAsString(':title', PlayItem.Title);
            DBTools.Query.AddParameterAsString(':artist', PlayItem.Artist);
            DBTools.Query.AddParameterAsString(':album', PlayItem.Album);
            DBTools.Query.AddParameterAsString(':year', PlayItem.Year);
            DBTools.Query.AddParameterAsDouble(':duration', PlayItem.Duration);

            DBTools.StartTransaction;
            try
              DBTools.ExecuteQuery;
              DBTools.Commit;
            except
              DBTools.Rollback;
              raise;
            end;
          end;
        finally
          DBTools.FreeQuery;
          FreeAndNil(DBTools);
        end;

        AOutParams.Clear;
      except
        on e: Exception do
        begin
          raise TDBExceptionContainer.CreateExceptionContainer(e, METHOD);
        end;
      end;
    end
  );

  try
    InParams := TParamsExt.Create;
    try
      InParams.Add(APlayItemsList, 'PlayItemsList');

      DBAParamsFunc(Proc, InParams, nil);
    finally
      FreeAndNil(InParams);
    end;
  except
    on e: Exception do
      ShowExceptionMessage(METHOD, e);
  end;
end;

procedure TDBAccess.DeleteFromCatalogTable(const APlayItemsList: TPlayItemsList);
const
  METHOD = 'TDBAccess.DeleteFromCatalogTable';
var
  Proc: TParamsProcRef;
  Path: String;
  FileName: String;
  InParams: TParamsExt;
begin
  Proc := (
    procedure(const AInParams: TParamsExt; const AOutParams: TParamsExt)
    var
      DBTools: TDBTools;
      SQLTemplateIdent: String;
      SQLTemplate: String;
      PlayItem: TPlayItem;
      PlayItemsList: TPlayItemsList;
    begin
      try
        PlayItemsList := AInParams.AsPointerByIdent['PlayItemsList'];

        SQLTemplateIdent := 'delete_from_catalog_table';
        SQLTemplate := SQLTemplates.GetTemplate(SQLTemplateIdent);

        DBTools := TDBTools.Create(DBFileName);
        try
          DBTools.CreateQuery;
          for PlayItem in PlayItemsList do
          begin
            DBTools.Query.ClearQuery;
            DBTools.Query.AddQuery(SQLTemplate);

            Path := ExtractFilePath(PlayItem.Path);
            FileName := ExtractFileName(PlayItem.Path);

            DBTools.Query.AddParameterAsString(':path', Path);
            DBTools.Query.AddParameterAsString(':file_name', FileName);

            DBTools.StartTransaction;
            try
              DBTools.ExecuteQuery;
              DBTools.Commit;
            except
              DBTools.Rollback;
              raise;
            end;
          end;
        finally
          DBTools.FreeQuery;
          FreeAndNil(DBTools);
        end;

        AOutParams.Clear;
      except
        on e: Exception do
        begin
          raise TDBExceptionContainer.CreateExceptionContainer(e, METHOD);
        end;
      end;
    end
  );

  try
    InParams := TParamsExt.Create;
    try
      InParams.Add(APlayItemsList, 'PlayItemsList');

      DBAParamsFunc(Proc, InParams, nil);
    finally
      FreeAndNil(InParams);
    end;
  except
    on e: Exception do
      ShowExceptionMessage(METHOD, e);
  end;
end;

procedure TDBAccess.SelectFromCatalogTable(
  const APath: String;
  const APlayItemsList: TPlayItemsList);
const
  METHOD = 'TDBAccess.SelectFromCatalogTable';
var
  Proc: TParamsProcRef;
  DBTools: TDBTools;
  SQLTemplateIdent: String;
  SQLTemplate: String;
  QueryResult: TDBQuery;
  InParams: TParamsExt;
  Path: String;
  DurationString: String;
begin
  Proc := (
    procedure(const AInParams: TParamsExt; const AOutParams: TParamsExt)
    var
      PlayItemsList: TPlayItemsList;
      PlayItem: TPlayItem;
    begin
      try
        Path := InParams.AsStringByIdent['Path'];
        PlayItemsList := InParams.AsPointerByIdent['PlayItemsList'];

        SQLTemplateIdent := 'select_from_catalog_table';
        SQLTemplate := SQLTemplates.GetTemplate(SQLTemplateIdent);
        if Length(Trim(SQLTemplate)) = 0 then
          raise Exception.
            Create(Format('SQL template "%s" not found or empty', [SQLTemplateIdent]));

        DBTools := TDBTools.Create(DBFileName);
        try
          DBTools.CreateQuery;
          DBTools.Query.ClearQuery;
          DBTools.Query.AddQuery(SQLTemplate);
          DBTools.Query.AddParameterAsString(':path', Path);

          QueryResult := DBTools.OpenQuery;
          while not QueryResult.Eof do
          begin
            PlayItem := TPlayItem.Create;

            PlayItem.Path := Concat(
              QueryResult.FindField('path').AsString,
              QueryResult.FindField('file_name').AsString);
            PlayItem.Title := QueryResult.FindField('title').AsString;
            PlayItem.Artist := QueryResult.FindField('artist').AsString;
            PlayItem.Album := QueryResult.FindField('album').AsString;
            PlayItem.Year := QueryResult.FindField('year').AsString;
            DurationString := QueryResult.FindField('duration').AsString;
            PlayItem.Duration := StrToInt64(DurationString);

            PlayItemsList.Add(PlayItem);

            QueryResult.Next;
          end;
          DBTools.CloseQuery;
        finally
          DBTools.FreeQuery;
          FreeAndNil(DBTools);
        end;

        AOutParams.Clear;
      except
        on e: Exception do
        begin
          raise TDBExceptionContainer.CreateExceptionContainer(e, METHOD);
        end;
      end;
    end);

  try
    InParams := TParamsExt.Create;
    try
      InParams.Add(APath, 'Path');
      InParams.Add(APlayItemsList, 'PlayItemsList');

      DBAParamsFunc(Proc, InParams, nil);
    finally
      FreeAndNil(InParams);
    end;
  except
    on e: Exception do
      ShowExceptionMessage(METHOD, e);
  end;
end;

end.
