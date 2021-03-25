
{$i deltics.consoleapp.inc}

  unit Deltics.ConsoleApp;


interface

  uses
    Classes,
    SysUtils,
    Deltics.CommandLine,
    Deltics.Console,
    Deltics.ConsoleApp.Errors,
    Deltics.ConsoleApp.Commands;


  type
    TCommand          = Deltics.ConsoleApp.Commands.TCommand;

    ECommandError     = Deltics.ConsoleApp.Errors.ECommandError;
    EInvalidArgument  = Deltics.ConsoleApp.Errors.EInvalidArgument;
    EInvalidOption    = Deltics.ConsoleApp.Errors.EInvalidOption;



  type
    TApplication = class(TCommand)
    private
      fVerboseSwitch: ICommandLineOption;
      fName: String;
      fHandleExceptions: Boolean;
      fTitle: String;
      constructor Create; reintroduce;

    protected
      function DoGetName: String; override;
      procedure DoRegister; override;

    public
      function ParseCommandTree(const aCommand: String): TCommand;

      procedure Execute;
      procedure DisplayHelp; overload; override;
      procedure DisplayHelp(aCommand: TCommand); reintroduce; overload;
      procedure RegisterCommand(aCommand: TCommandClass);
      procedure SetName(const aValue: String);
      procedure SetReportExceptions(const aValue: Boolean);
      procedure SetTitle(const aValue: String);

      property HandleExceptions: Boolean read fHandleExceptions;
      property Title: String read fTitle;
      property Verbose: ICommandLineOption read fVerboseSwitch;
    end;



  var
    Application: TApplication;



implementation

  uses
    Windows,
    Deltics.Strings,
    Deltics.ConsoleApp.HELP;


  type
    TCommandHelper = class(Deltics.ConsoleApp.Commands.TCommand);


  function IsDebuggerPresent: Boolean; external kernel32 name 'IsDebuggerPresent';


  constructor TApplication.Create;
  begin
    inherited Create;

    fTitle := Name;

    RegisterCommand(HELP);
  end;


  procedure TApplication.DisplayHelp;
  begin

  end;


  procedure TApplication.DisplayHelp(aCommand: TCommand);
  begin

  end;


  function TApplication.ParseCommandTree(const aCommand: String): TCommand;
  begin
    // ?
    result := NIL;
  end;


  procedure TApplication.Execute;
  var
    key: Char;

    procedure Done;
    begin
      if IsDebuggerPresent then
      begin
        if Console.CursorPos.Col <> 1 then
          Console.WriteLn;

        Console.WriteLn;
        Console.WriteLn(' @blue(Application terminated normally.)');
        Console.WriteLn(' @blue(Press any key to close the console)');

        Read(key);
      end;
    end;

  var
    app: TCommand;
  begin
    try
      Console.PushAttr(Console.Attr);
      try
        if CommandLine.Params.Count > 0 then
        begin
          app := FindCommand(CommandLine.Params[0]);
          if Assigned(app) then
            TCommandHelper(app).Execute;
        end;

        Done;

      finally
        Console.PopAttr;
      end;

    except
      on EAbort do Done;

      on e: Exception do
      begin
        if NOT fHandleExceptions then
          raise;

        if Console.CursorPos.Col <> 1 then
          Console.WriteLn;

        Console.NoIndent;
        try
          repeat
            Console.WriteLn('-> @red(%s: %s)', [e.ClassName, e.Message]);

          {$ifdef DELPHI XE4__}
            e := e.InnerException;
            Console.Indent(3);
          {$else}
            e := NIL;
          {$endif}
          until NOT Assigned(e);

        finally
          Console.NoIndent;
        end;
      end;
    end;
  end;



  procedure TApplication.RegisterCommand(aCommand: TCommandClass);
  begin
    inherited;
  end;


  procedure TApplication.SetName(const aValue: String);
  begin
    fName := aValue;
  end;


  procedure TApplication.SetReportExceptions(const aValue: Boolean);
  begin
    fHandleExceptions := aValue;
  end;


  procedure TApplication.SetTitle(const aValue: String);
  begin
    fTitle := aValue;
  end;


  function TApplication.DoGetName: String;
  begin
    result := fName;

    if result = '' then
      result := STR.Lowercase(ChangeFileExt(ExtractFilename(CommandLine.ExeFilename), ''));
  end;


  procedure TApplication.DoRegister;
  begin
    fVerboseSwitch := RegisterSwitch('--verbose', '-v');
  end;




initialization
  Application := TApplication.Create;

finalization
  Application.Free;

end.
