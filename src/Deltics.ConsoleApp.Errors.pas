
{$i deltics.consoleapp.inc}

  unit Deltics.ConsoleApp.Errors;


interface

  uses
    SysUtils;


  type
    ECommandError = class(Exception)
    public
      constructor Create(const aMessage: String; aArgs: array of const); reintroduce; overload;
    end;


    EInvalidArgument = class(ECommandError);
    EInvalidOption = class(ECommandError);



implementation


  constructor ECommandError.Create(const aMessage: String; aArgs: array of const);
  begin
    inherited CreateFmt(aMessage, aArgs);
  end;



end.
