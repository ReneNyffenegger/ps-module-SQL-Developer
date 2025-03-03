@{
   RootModule        = 'SQL-Developer.psm1'
   ModuleVersion     = '0.7'

   RequiredModules   = @(
      'console'
   )

   FunctionsToExport = @(
     'get-SQLDeveloperUserInformationDirectory',

     'get-SQLDeveloperUserPreferencesFileName'    , 'get-SQLDeveloperUserPreferencesXml',
     'get-SQLDeveloperUserConnectionsFileName'    , 'get-SQLDeveloperUserConnectionsPSObjects',

     'get-SQLDeveloperDBSystemId',

     'set-SQLDeveloperFontFamily'                 , 'get-SQLDeveloperFontFamily',
     'set-SQLDeveloperFontSize'                   , 'get-SQLDeveloperfontSize',

     'set-SQLDeveloperUseCaseDelimitedWord'       , 'get-SQLDeveloperUseCaseDelimitedWord',

     'set-SQLDeveloper_TNS_NAMES_directory'       , 'get-SQLDeveloper_TNS_NAMES_directory',

     'set-SQLDeveloper_NLS_DATE_FORMAT'           , 'get-SQLDeveloper_NLS_DATE_FORMAT',
     'set-SQLDeveloper_NLS_TIMESTAMP_FORMAT'      , 'get-SQLDeveloper_NLS_TIMESTAMP_FORMAT',
     'set-SQLDeveloper_NLS_TIMESTAMP_TZ_FORMAT'   , 'get-SQLDeveloper_NLS_TIMESTAMP_TZ_FORMAT',

     'set-SQLDeveloper_NULL_text'                 , 'get-SQLDeveloper_NULL_text',
     'set-SQLDeveloper_NULL_color'                , 'get-SQLDeveloper_NULL_color',

     'set-SQLDeveloperNewWorksheetConnection'     , 'get-SQLDeveloperNewWorksheetConnection'     ,

     'set-SQLDeveloperArrayFetchSize'             , 'get-SQLDeveloperArrayFetchSize'             ,
     'set-SQLDeveloperUseThickDriver'             , 'get-SQLDeveloperUseThickDriver'             ,
     'set-SQLDeveloperStartupScript'              , 'get-SQLDeveloperStartupScript'              ,
     'set-SQLDeveloperKerberosThinConfigFile'     , 'get-SQLDeveloperKerberosThinConfigFile'     ,
     'set-SQLDeveloperKerberosThinCredentialCache', 'get-SQLDeveloperKerberosThinCredentialCache',

     'set-SQLDeveloper_glogin'                    , 'get-SQLDeveloper_glogin'                    ,

     'add-SQLDeveloperCodeTemplate',
     'remove-SQLDeveloperSystemCache'

   )

   AliasesToExport   = @()
}
