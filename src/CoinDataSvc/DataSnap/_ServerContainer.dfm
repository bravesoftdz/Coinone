object ServerContainer: TServerContainer
  OldCreateOrder = False
  OnCreate = ServiceCreate
  AllowPause = False
  DisplayName = 'DataSnap Service Templete'
  AfterInstall = ServiceAfterInstall
  AfterUninstall = ServiceAfterUninstall
  OnExecute = ServiceExecute
  OnShutdown = ServiceShutdown
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 271
  Width = 415
  object DSServer: TDSServer
    AutoStart = False
    Left = 96
    Top = 11
  end
  object DSTCPServerTransport: TDSTCPServerTransport
    Server = DSServer
    Filters = <>
    Left = 96
    Top = 73
  end
  object DSHTTPService: TDSHTTPService
    HttpPort = 8080
    Server = DSServer
    Filters = <>
    Left = 96
    Top = 135
  end
  object dscDataProvider: TDSServerClass
    OnGetClass = dscDataProviderGetClass
    Server = DSServer
    LifeCycle = 'Server'
    Left = 208
    Top = 11
  end
  object dsDataLoader: TDSServerClass
    OnGetClass = dsDataLoaderGetClass
    Server = DSServer
    LifeCycle = 'Server'
    Left = 208
    Top = 75
  end
end
