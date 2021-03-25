
{$i deltics.consoleapp.inc}

  unit Deltics.ConsoleApp.FileProcessing;


interface

  uses
    SysUtils,
    Deltics.CommandLine,
    Deltics.ConsoleApp.Commands,
    Deltics.IO.FindFiles,
    Deltics.IO.SearchPath,
    Deltics.Strings;


  type
    TFileProcessingCommand = class(TCommand)
    private
      fDirs: ISearchPath;
      fFiles: TFileList;
      fRecursiveSwitch: ICommandLineOption;
      fRootDir: String;
      fRootSwitch: ICommandLineOption;
      procedure PreProcessFile(const aFilename: UnicodeString);
      function ProcessFile(const aFilename: UnicodeString): Boolean;

    protected
      procedure Cleanup; override;
      procedure DoParseParams; override;
      procedure DoExecute; override;
      procedure DoRegister; override;

      property Dirs: ISearchPath read fDirs;
      property Files: TFileList read fFiles;

    protected
      procedure DoPreProcessFile(const aFilename: UnicodeString); overload; virtual;
      procedure DoProcessFile(const aFilename: UnicodeString); overload; virtual;
      procedure DoProcessFile(const aFilename: UnicodeString; var aProcessed: Boolean); overload; virtual;
      procedure DoAfterFilesInFolder(const aPath: UnicodeString); virtual;
      procedure DoAfterAllFiles; virtual;

      function RelativePath(aPath: String): String; overload;
      function RelativePath(aDir, aFile: String): String; overload;
    end;


implementation

  uses
    Deltics.Console,
    Deltics.IO.Path;



{ TFileProcessingCommand }

  procedure TFileProcessingCommand.Cleanup;
  begin
    inherited;

    FreeAndNIL(fFiles);
  end;


  procedure TFileProcessingCommand.DoAfterAllFiles;
  begin
    { NO-OP }
  end;


  procedure TFileProcessingCommand.DoAfterFilesInFolder(const aPath: UnicodeString);
  begin
    { NO-OP }
  end;


  procedure TFileProcessingCommand.DoExecute;
  var
    i, j: Integer;
    filename: UnicodeString;
  begin
    inherited;

    for i := 0 to Pred(fDirs.Count) do
    begin
      fFiles.Folder := fDirs[i];

//      Console.SetProcessingMessage('Pre-Processing ' + fDirs[i] + '...');
      try
        for j := 0 to Pred(fFiles.Count) do
        begin
          filename := Path.Append(Dirs[i], Files[j]);
          try
            PreProcessFile(filename);

          except
            on e: Exception do
            begin
              e.Message := e.Message + #13#10
                         + 'Pre-Processing file: ' + RelativePath(filename);
              raise;
            end;
          end;
        end;

      finally
//        Console.ClearProcessingMessage;
      end;

//      Console.SetProcessingMessage('Processing ' + fDirs[i] + '...');
      try
        for j := 0 to Pred(fFiles.Count) do
        begin
          filename := Path.Append(Dirs[i], Files[j]);
          try
            ProcessFile(filename);

          except
            on e: Exception do
            begin
              e.Message := e.Message + #13#10
                         + 'Processing file: ' + RelativePath(filename);
              raise;
            end;
          end;
        end;

        DoAfterFilesInFolder(fDirs[i]);

      finally
//        Console.ClearProcessingMessage;
      end;
    end;
  end;


  procedure TFileProcessingCommand.DoParseParams;
  begin
    inherited;

    fRootDir := fRootSwitch.ValueOrDefault(Path.CurrentDir);

    if fRecursiveSwitch.IsEnabled then
      fDirs := SearchPath.New(Path.Append(fRootDir, '**'))
    else
      fDirs := SearchPath.New(fRootDir);

    fFiles := TFileList.Create;
  end;


  procedure TFileProcessingCommand.DoProcessFile(const aFilename: UnicodeString);
  begin
    // NO-OP
  end;


  procedure TFileProcessingCommand.DoPreProcessFile(const aFilename: UnicodeString);
  begin
    // NO-OP
  end;


  procedure TFileProcessingCommand.DoProcessFile(const aFilename: UnicodeString; var aProcessed: Boolean);
  begin
    aProcessed := FALSE;
  end;


  procedure TFileProcessingCommand.PreProcessFile(const aFilename: UnicodeString);
  begin
    DoPreprocessFile(aFilename);
  end;


  function TFileProcessingCommand.ProcessFile(const aFilename: UnicodeString): Boolean;
  begin
    result := TRUE;

    DoProcessFile(aFilename);
    DoProcessFile(aFilename, result);
  end;


  function TFileProcessingCommand.RelativePath(aPath: String): String;
  begin
    result := Path.AbsoluteToRelative(aPath, fRootDir);
  end;


  function TFileProcessingCommand.RelativePath(aDir, aFile: String): String;
  begin
    result := RelativePath(Path.Append(aDir, aFile));
  end;


  procedure TFileProcessingCommand.DoRegister;
  begin
    fRecursiveSwitch  := RegisterSwitch('--recursive', '-r');
    fRootSwitch       := RegisterSwitch('--rootFolder', '-rf');
  end;



end.
