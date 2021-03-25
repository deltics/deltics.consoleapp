
{$i deltics.consoleapp.inc}

  unit Deltics.ConsoleApp.HELP;


interface

  uses
    Deltics.ConsoleApp.Commands;


  type
    HELP = class(TCommand)
    protected
      procedure DoExecute; override;
      procedure DisplayForCommand(aCommand: TCommand);
    end;


implementation

  uses
    Deltics.Console,
    Deltics.ConsoleApp;


  type
    TCommandHelper = class(TCommand);


  procedure HELP.DoExecute;
  var
    i, j: Integer;
    cmd: TCommand;
    target: TCommand;
  begin
    // If arguments are provided to the HELP command then we try to find an application command
    //  based on treating the arguments as a "command tree" for that applicationm e.g:
    //
    //    APP HELP command1, command2, command3
    //
    // We will try to display help for the sub-command command3 of command2 which in turn is
    //  a sub-command of command1

    if Params.Count > 0 then
    begin
      target := Application.FindCommand(Params[0]);

      if Assigned(target) and (Params.Count > 1) then
        for i := 1 to Pred(Params.Count) do
        begin
          cmd := target.FindCommand(Params[i]);
          if NOT Assigned(cmd) then
          begin
            for j := i to Pred(Params.Count) do
              target.Params.Add(Params[j]);

            BREAK;
          end
          else
            target := cmd
        end;
    end
    else
      target := NIL;

    if NOT Assigned(target) then
    begin
      Console.WriteLn;
      Console.WriteLn(Application.Title + ' version 0.0.0.1');
      Console.WriteLn;
      Console.WriteLn(' usage: @cyan(%s <command>) @pink([args] [options])', [Application.Name]);
      Console.WriteLn;

      Console.WriteLn('  Available commands:');
      Console.WriteLn;

      for i := 0 to Pred(Application.Commands.Count) do
      begin
        cmd := Application.Commands[i];
        Console.WriteLn('   @cyan(%s)', [cmd.Name]);
      end;

      Console.WriteLn;
      Console.WriteLn('  Type: @cyan(%s help) @red(<command>) for help with a specific command', [Application.Name]);
      Console.WriteLn;
    end
    else
      DisplayForCommand(target);
  end;


  procedure HELP.DisplayForCommand(aCommand: TCommand);
  begin
    Console.WriteLn;
    Console.WriteLn(' usage: @cyan(%s %s)', [Application.Name, aCommand.FullName]);
    Console.WriteLn;

    TCommandHelper(aCommand).DisplayHelp;
  end;





end.
