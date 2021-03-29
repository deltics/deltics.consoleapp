
{$i deltics.consoleapp.inc}

  unit Deltics.ConsoleApp.FileProcessing;


interface

  uses
    SysUtils,
    Deltics.CommandLine,
    Deltics.ConsoleApp.Commands,
    Deltics.StringLists,
    Deltics.StringTypes;


  type
    TFileProcessingCommand = class(TCommand)
    private
      fFolders: IStringList;
      fFilenames: IStringList;
      fRecursiveSwitch: ICommandLineOption;
      fRootSwitch: ICommandLineOption;
      procedure PreProcessFile(const aFilename: UnicodeString);
      function ProcessFile(const aFilename: UnicodeString): Boolean;

    protected
      procedure DoParseParams; override;
      procedure DoExecute; override;
      procedure DoRegister; override;

      property Folders: IStringList read fFolders;
      property Filenames: IStringList read fFilenames;

    protected
      procedure DoPreProcessFile(const aFilename: UnicodeString); overload; virtual;
      procedure DoProcessFile(const aFilename: UnicodeString); overload; virtual;
      procedure DoProcessFile(const aFilename: UnicodeString; var aProcessed: Boolean); overload; virtual;
      procedure DoAfterFilesInFolder(const aPath: UnicodeString); virtual;
      procedure DoAfterAllFiles; virtual;

//      function RelativePath(aPath: String): String; overload;
//      function RelativePath(aDir, aFile: String): String; overload;
    end;


implementation

  uses
    Deltics.Console,
    Deltics.IO.FileSearch,
    Deltics.IO.Path;



{ TFileProcessingCommand }

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
    search: IFileSearch;
    files: IStringList;
    filename: String;
  begin
    inherited;

    search := FileSearch
      .Yielding.FullyQualified
      .Yielding.Files(files);

    for i := 0 to Pred(fFilenames.Count) do
      search.Filename(fFilenames[i]);

    for i := 0 to Pred(fFolders.Count) do
    begin
      search.Folder(fFolders[i], TRUE);

      if NOT search.Execute then
      begin
//      Console.SetProcessingMessage('No files to process in ' + fFolders[i]);
        CONTINUE;
      end;

//      Console.SetProcessingMessage('Pre-Processing ' + fFolders[i] + '...');
      try
        for j := 0 to Pred(files.Count) do
        begin
          try
            PreProcessFile(files[j]);

          except
            on e: Exception do
            begin
              filename := Path.AbsoluteToRelative(files[j], fFolders[i]);
              e.Message := e.Message + #13#10 + 'Pre-Processing file: ' + filename;
              raise;
            end;
          end;
        end;

      finally
//        Console.ClearProcessingMessage;
      end;

//      Console.SetProcessingMessage('Processing ' + fDirs[i] + '...');
      try
        for j := 0 to Pred(files.Count) do
        begin
          try
            ProcessFile(files[j]);

          except
            on e: Exception do
            begin
              filename := Path.AbsoluteToRelative(files[j], fFolders[i]);
              e.Message := e.Message + #13#10 + 'Processing file: ' + filename;
              raise;
            end;
          end;
        end;

        DoAfterFilesInFolder(fFolders[i]);

      finally
//        Console.ClearProcessingMessage;
      end;
    end;
  end;


  procedure TFileProcessingCommand.DoParseParams;
  begin
    inherited;

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


(*  function TFileProcessingCommand.RelativePath(aPath: String): String;
  begin
    result := Path.AbsoluteToRelative(aPath, fRootDir);
  end;


  function TFileProcessingCommand.RelativePath(aDir, aFile: String): String;
  begin
    result := RelativePath(Path.Append(aDir, aFile));
  end;
*)

  procedure TFileProcessingCommand.DoRegister;
  begin
    fRecursiveSwitch  := RegisterSwitch('--recursive', '-r');
    fRootSwitch       := RegisterSwitch('--rootFolder', '-rf');
  end;



end.
