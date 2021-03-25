
{$i deltics.consoleapp.inc}

  unit Deltics.ConsoleApp.Commands;


interface

  uses
    Classes,
    Contnrs,
    SysUtils,
    Deltics.CommandLine,
    Deltics.InterfacedObjects,
    Deltics.StringLists,
    Deltics.Strings,
    Deltics.Console,
    Deltics.ConsoleApp.Errors;


  type
    TCommand = class;
    TCommandList = class;
    TCommandClass = class of TCommand;



    TCommandSwitchList = class(TInterfaceList)
    private
      function get_Item(const aIndex: Integer): ICommandLineOption;
    public
      function Register(const aSwitch: String; const aShortSwitch: String; const aDefaultValue: String = ''): ICommandLineOption;
      property Items[const aIndex: Integer]: ICommandLineOption read get_Item; default;
    end;



    TCommand = class(TInterfacedObject)
    private
      fParams: IStringList;
      fCommands: TCommandList;
      fDetailedHelp: TStringList;
      fDetailedHelpSummary: TStringList;
      fName: String;
      fParent: TCommand;
      fSwitches: TCommandSwitchList;
//      function get_Application: TApplication;
      function get_Name: String;

      procedure IdentifyArguments;
      function get_FullName: String;
      function get_Console: ConsoleClass;

    protected
      procedure DetailedHelp(const aSummary: String); overload;
      procedure DetailedHelp(const aID: String; const aSummary: String; const aHelp: String); overload;
      function DetailedHelpText(const aID: String): TStringList; overload;
      function DetailedHelpText(const aIndex: Integer): TStringList; overload;
      function HasDetailedHelp: Boolean; overload;
      function HasDetailedHelp(const aID: String; var aIndex: Integer): Boolean; overload;
      function InvalidArgument(const aMessage: String): EInvalidArgument; overload;
      function InvalidArgument(const aMessage: String; aArgs: array of const): EInvalidArgument; overload;

      function DoGetName: String; virtual;
      procedure DoRegister; virtual;
      procedure DoDisplayHelp; virtual;

      procedure DoParseParams; virtual;
      procedure DoExecute; virtual;

      procedure DisplayHelp; virtual;
      procedure ParseParams;
      procedure Cleanup; virtual;
      procedure Execute; overload;
      procedure Setup; virtual;
      function RegisterSwitch(const aSwitch: String; const aAlias: String; const aDefaultValue: String = ''): ICommandLineOption;

      procedure DoRegisterCommands; virtual;
      procedure RegisterCommand(aCommand: TCommandClass);

    public
      class procedure Register;
      constructor Create; overload;
      constructor Create(const aParent: TCommand); overload;
      procedure AfterConstruction; override;
      destructor Destroy; override;

      function FindCommand(const aName: String): TCommand;

//      property Application: TApplication read get_Application;
      property Params: IStringList read fParams;
      property Switches: TCommandSwitchList read fSwitches;
      property Commands: TCommandList read fCommands;
      property Console: ConsoleClass read get_Console;
      property FullName: String read get_FullName;
      property Name: String read get_Name;
      property Parent: TCommand read fParent;
    end;



    TCommandList = class(TObjectList)
    private
      function get_Item(const aIndex: Integer): TCommand;
    public
      property Items[const aIndex: Integer]: TCommand read get_Item; default;
    end;



implementation

  uses
//    Deltics.Radiata,
    Deltics.ConsoleApp,
    Deltics.CommandLine.Options;


{ TCommand }

  constructor TCommand.Create;
  begin
    inherited Create;

    fParams   := TStringList.CreateManaged;
    fCommands := TCommandList.Create;
    fSwitches := TCommandSwitchList.Create;

    fDetailedHelp         := TStringList.Create;
    fDetailedHelpSummary  := TStringList.Create;
  end;


  constructor TCommand.Create(const aParent: TCommand);
  begin
    Create;

    fParent := aParent;
  end;


  procedure TCommand.AfterConstruction;
  begin
    inherited;

    DoRegisterCommands;
  end;


  destructor TCommand.Destroy;
  begin
    while (fDetailedHelp.Count > 0) do
    begin
      fDetailedHelp.Objects[0].Free;
      fDetailedHelp.Delete(0);
    end;
    FreeAndNIL(fDetailedHelp);
    FreeAndNIL(fDetailedHelpSummary);

    FreeAndNIL(fSwitches);
    FreeAndNIL(fCommands);

    inherited;
  end;


  procedure TCommand.DetailedHelp(const aSummary: String);
  begin
    fDetailedHelpSummary.Text := aSummary;
  end;


  procedure TCommand.DetailedHelp(const aID, aSummary, aHelp: String);
  var
    help: TStringList;
  begin
    help := TStringList.Create;
    help.Text := aHelp;

    fDetailedHelp.AddObject(STR.Uppercase(aID) + '=' + aSummary, help);
  end;


  function TCommand.DetailedHelpText(const aID: String): TStringList;
  var
    idx: Integer;
  begin
    if HasDetailedHelp(aID, idx) then
      result := DetailedHelpText(idx)
    else
      result := NIL;
  end;


  function TCommand.DetailedHelpText(const aIndex: Integer): TStringList;
  begin
    result := TStringList(fDetailedHelp.Objects[aIndex]);
  end;


  function TCommand.FindCommand(const aName: String): TCommand;
  var
    i: Integer;
  begin
    for i := 0 to Pred(fCommands.Count) do
    begin
      result := fCommands[i];
      if Str.SameText(result.Name, aName) then
        EXIT;
    end;

    result := NIL;
  end;


  class procedure TCommand.Register;
  begin
    Application.RegisterCommand(self);
  end;



  procedure TCommand.RegisterCommand(aCommand: TCommandClass);
  var
    i: Integer;
    cmd: TCommand;
  begin
    for i := 0 to Pred(fCommands.Count) do
    begin
      if fCommands[i].ClassType = aCommand then
        EXIT;
    end;

    cmd := aCommand.Create;

    if NOT (self is TApplication) then
      cmd.fParent := self;

    cmd.DoRegister;

    fCommands.Add(cmd);
  end;


  function TCommand.RegisterSwitch(const aSwitch: String;
                                   const aAlias: String;
                                   const aDefaultValue: String): ICommandLineOption;
  var
    i: Integer;
  begin
    for i := 0 to Pred(CommandLine.Options.Count) do
    begin
      result := CommandLine.Options[i];
      if Str.SameText(result.Name, aSwitch)
       or Str.SameText(result.Name, aAlias) then
        EXIT;
    end;

    result := TCommandLineOption.Create(aSwitch, aDefaultValue);
  end;


  procedure TCommand.Setup;
  begin
    // NO-OP
  end;


  procedure TCommand.Cleanup;
  begin
    // NO-OP
  end;


  procedure TCommand.DoDisplayHelp;
  begin
    Console.WriteLn('Sorry, no help is available for @cyan(%s %s)', [Application.Name, FullName]);

    if Assigned(Parent) then
    begin
      Console.WriteLn;
      Parent.DisplayHelp;
    end;
  end;


  procedure TCommand.DisplayHelp;
  var
    idx: Integer;
  begin
    if (Params.Count > 0) and HasDetailedHelp(Params[0], idx) then
    begin
//      Console.Write(DetailedHelpText(idx), 4, 4);
      Console.Write(DetailedHelpText(idx));
      Console.WriteLn;
    end
    else if (Params.Count = 0) and HasDetailedHelp then
    begin
    end
    else
      DoDisplayHelp;
  end;


  procedure TCommand.DoExecute;
  begin
    { NO-OP }
  end;


  function TCommand.DoGetName: String;
  begin
    result := STR.Lowercase(ClassName);

    STR.ConsumeRight(result, 'command', csIgnoreCase);
  end;


  procedure TCommand.DoParseParams;
  begin
    // NO-OP
  end;


  procedure TCommand.DoRegister;
  begin
    // NO-OP - override in subclasses to register any switches or other registration setup
  end;


  procedure TCommand.DoRegisterCommands;
  begin
    // NO-OP - override in subclasses to register any sub-commands
  end;


  procedure TCommand.Execute;
  var
    cmd: TCommand;
  begin
    IdentifyArguments;

    if Params.Count > 0 then
      cmd := FindCommand(Params[0])
    else
      cmd := NIL;

    if Assigned(cmd) then
    begin
      cmd.Execute;
      EXIT;
    end;

    // This is the command we need to execute

    ParseParams;
    Setup;
    try
      DoExecute;

    finally
      Cleanup;
    end;
  end;


//  function TCommand.get_Application: TApplication;
//  begin
//    result := Deltics.Console.Application.Application;
//  end;


  function TCommand.get_Console: ConsoleClass;
  begin
    result := Deltics.Console.Console;
  end;


  function TCommand.get_FullName: String;
  begin
    if Assigned(Parent) then
      result := Parent.FullName + ' ' + Name
    else
      result := Name;
  end;


  function TCommand.get_Name: String;
  begin
    if fName = '' then
      fName := DoGetName;

    result := fName;
  end;


  function TCommand.HasDetailedHelp: Boolean;
  begin
    result := fDetailedHelp.Count > 0;
  end;


  function TCommand.HasDetailedHelp(const aID: String;
                                    var aIndex: Integer): Boolean;
  begin
    aIndex := fDetailedHelp.IndexOfName(STR.Uppercase(aID));
    result := aIndex <> -1;
  end;


  procedure TCommand.IdentifyArguments;
  var
    i: Integer;
    parent: TCommand;
    args: IStringList;
  begin
    inherited;

    // Identify (and ignore) arguments that correspond to parent commands

    i       := 1;
    parent  := self.Parent;
    while Assigned(parent) do
    begin
      Inc(i);
      parent := parent.Parent;
    end;

    args := TStringList.CreateManaged;

    for i := i to Pred(CommandLine.Params.Count) do
      fParams.Add(CommandLine.Params[i]);

    EXIT;

(*
  // TODO: The old approach to switch registration allowed us to detect switches that
  //        were being ignored by a command.  The new approach doesn't.  FIX THIS!
  //
  //       (Should be simple: Just remember that REGISTERED switches are a feature of
  //        CONSOLE APP COMMANDS, not the command itself!)
  //
  // NOTE: Uses Radiata

    fSwitches.Parse(args);

    for i := 0 to Pred(args.Count) do
    begin
      arg := args[i];
      if ANSIChar(arg[1]) in ['-', '/', '+'] then
        Log.Hint('Console app command is ignoring unrecognised switch ''{switch}''', [arg])
      else
        fArguments.Add(arg);
    end;
*)
  end;


  function TCommand.InvalidArgument(const aMessage: String): EInvalidArgument;
  begin
    result := EInvalidArgument.Create(aMessage);
  end;


  function TCommand.InvalidArgument(const aMessage: String; aArgs: array of const): EInvalidArgument;
  begin
    result := EInvalidArgument.Create(aMessage, aArgs);
  end;


  procedure TCommand.ParseParams;
  begin
    DoParseParams;
  end;



{ TCommandSwitchList }

  function TCommandSwitchList.get_Item(const aIndex: Integer): ICommandLineOption;
  begin
    result := (inherited Items[aIndex]) as ICommandLineOption;
  end;


  function TCommandSwitchList.Register(const aSwitch, aShortSwitch, aDefaultValue: String): ICommandLineOption;

  begin
    result := NIL;

    if CommandLine.Options.Contains(aSwitch, result) then
      result.Alts.Add(aShortSwitch);

    if NOT Assigned(result)
     and (aShortSwitch <> '')
     and CommandLine.Options.Contains(aShortSwitch, result) then
      result.Alts.Add(aSwitch);

    if NOT Assigned(result) then
    begin
      result := TCommandLineOption.Create(aSwitch, aDefaultValue);

      if aShortSwitch <> '' then
        result.Alts.Add(aShortSwitch);
    end;
  end;






{ TCommandList }

  function TCommandList.get_Item(const aIndex: Integer): TCommand;
  begin
    result := TCommand(inherited Items[aIndex]);
  end;




end.
