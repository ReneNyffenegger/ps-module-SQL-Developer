set-strictMode -version 3

function get-SQLDeveloperUserInformationDirectory {

   $dir = get-childItem -attributes directory "$env:appdata\SQL Developer\system*" | where-object {$_.name -match '^system(\d+)\.(\d+)\.(\d+)\.(\d+)\.(\d+)$' }

   if ($dir -eq $null) {
      write-textInConsoleErrorColor "User information directory does not exist or was not found."
      return $null
   }

   if ($dir -is [array]) {
      write-textInConsoleErrorColor "Unable to determine user information directory uniquely"
      return $null
   }

   return $dir
}

# { User preference file

function get-SQLDeveloperUserPreferencesFileName {

   $userInfoDir = get-SQLDeveloperUserInformationDirectory
   if ($userInfoDir -eq $null) {
      return
   }

   $userPreferencesFile = "$userInfoDir/o.sqldeveloper/product-preferences.xml"

   if (! (test-path $userPreferencesFile) ) {
      write-textInConsoleErrorColor "User Preferences file ($userPreferencesFile) not found."
      return $null
   }

   return $userPreferencesFile
}

function get-SQLDeveloperUserPreferencesXml {

   $productPreferencesFile = get-SQLDeveloperUserPreferencesFileName
   if ($productPreferencesFile -eq $null) {
      return
   }

   [xml] $doc = new-object xml
   $doc.Load($productPreferencesFile)

   return $doc

}

# }

# { User connections file

function get-SQLDeveloperUserConnectionsFileName {

   $userInfoDir = get-SQLDeveloperUserInformationDirectory
   if ($userInfoDir -eq $null) {
      return
   }

   $connectionsJsonFileName = "$userInfoDir/o.jdeveloper.db.connection/connections.json"

   if (test-path $connectionsJsonFileName) {
      return $connectionsJsonFileName
   }

   $connectionsXMLfileName = "$userInfoDir/o.jdeveloper.db.connection/connections.xml"
   if (test-path $connectionsXMLfileName) {
      return $connectionsXMLfileName
   }

   write-textInConsoleErrorColor "Neither $connectionsJsonFileName nor $connectionsXMLfileName found"
   return $null
}

function get-SQLDeveloperUserConnectionsPSObjects {

   function local:null-if-nothing($x, $y) {if ($x.psObject.properties.name -contains $y){$x.$y} else {$null} }

   $connections = (convertFrom-json (get-content (get-SQLDeveloperUserConnectionsFileName))).connections

   foreach ($connection in $connections) {
      $ret = new-object psObject -property ([ordered] @{
         name                             = $connection.name
         type                             = $connection.type
         subtype                          = null-if-nothing   $connection.info  subtype
         role                             = null-if-nothing   $connection.info  role
         SavePassword                     = null-if-nothing   $connection.info  SavePassword
         OracleConnectionType             = null-if-nothing   $connection.info  OracleConnectionType
         ProxyType                        = null-if-nothing   $connection.info  PROXY_TYPE
         RaptorConnectionType             = null-if-nothing   $connection.info  RaptorConnectionType
         customUrl                        = null-if-nothing   $connection.info  customUrl
         oraDriverType                    = null-if-nothing   $connection.info  oraDriverType
         NoPasswordConnection             = null-if-nothing   $connection.info  NoPasswordConnection
         password                         = null-if-nothing   $connection.info  password
         hostname                         = null-if-nothing   $connection.info  hostname
         driver                           = null-if-nothing   $connection.info  driver
         port                             = null-if-nothing   $connection.info  port
         OSAuthentication                 = null-if-nothing   $connection.info  OS_AUTHENTICATION
         IS_PROXY                         = null-if-nothing   $connection.info  IS_PROXY
         KerberosAuthentication           = null-if-nothing   $connection.info  KerberosAuthentication
         ProxyUserName                    = null-if-nothing   $connection.info  PROXY_USER_NAME
         user                             = null-if-nothing   $connection.info  user

         sqlserver_default_password       = null-if-nothing   $connection.info  sqlserver_default_password
         sqlserver_domain                 = null-if-nothing   $connection.info  sqlserver_domain
         sqlserver_windows_authentication = null-if-nothing   $connection.info  sqlserver_windows_authentication

      })

      $ret
   }
}

# }

function get-SQLDeveloperDBSystemId {
 #
 # TODO: Similar code in function get-preferences
 #
   [xml] $doc = get-SQLDeveloperUserPreferencesXml

   $nameTable = new-object System.Xml.NameTable
   $nsMgr     = new-object System.Xml.XmlNamespaceManager $nameTable
   $nsMgr.AddNamespace('ide', 'http://xmlns.oracle.com/ide/hash')

   $valueName = 'db.system.id'

   $value = $doc.SelectSingleNode('/ide:preferences//value[@n="' + $valueName + '"]', $nsMgr)

   if ($value -eq $null) {
      return $null
   }
   return $value.GetAttribute('v')
}

# { Internal helper functions

function set-preference {

   param (
      [string] $hashName,
      [string] $valueName,
      [object] $newValue
   )

   if ($newValue -is [bool]) {
      if ($newValue) { $newValue_ = 'true' } else { $newValue_ = 'false' }
   }
   else {
      $newValue_ = $newValue
   }

   $productPreferencesFile = get-SQLDeveloperUserPreferencesFileName
   if ($productPreferencesFile -eq $null) {
      return
   }

   $nameTable = new-object System.Xml.NameTable
   $nsMgr     = new-object System.Xml.XmlNamespaceManager $nameTable
   $nsMgr.AddNamespace('ide', 'http://xmlns.oracle.com/ide/hash')

<#

   [xml] $doc = new-object xml
   $doc.Load($productPreferencesFile)

#>
   [xml] $doc = get-SQLDeveloperUserPreferencesXml

   [System.Xml.XmlElement] $preferences = $doc.SelectSingleNode('/ide:preferences', $nsMgr)

   if ($preferences -eq $null) {
      write-textInConsoleErrorColor "Node /ide:preferences was not found in $productPreferencesFile"
   }

   $hashElem = $preferences.SelectSingleNode('hash[@n="' + $hashName + '"]', $nsMgr) # FontSizeOptions"]', $nsMgr)
   if ($hashElem -eq $null) {
      $hashElem = $doc.CreateElement('hash')
      $hashElem.SetAttribute('n', $hashName)
      $null = $preferences.AppendChild($hashElem)
   }

   $valueElem = $hashElem.SelectSingleNode('value[@n="' + $valueName + '"]')
   if ($valueElem -eq $null) {
      $valueElem = $doc.CreateElement('hash')
      $valueElem.SetAttribute('n', $valueName)
      $null = $hashElem.AppendChild($valueElem)
   }

   $valueElem.SetAttribute('v', $newValue_)

 #
 # Use Stream writer to control line ending:
 #
   $sw = new-object System.IO.StreamWriter $productPreferencesFile
   $sw.NewLine = "`n"

   $xw = new-object System.Xml.XmlTextWriter $sw
   $xw.Formatting  = 'Indented'
   $xw.IndentChar  = ' '
   $xw.Indentation = 3

   $doc.Save($xw)
   $sw.Close()

}

function get-preference {

 #
 # TODO: Similar code in get-SQLDeveloperDBSystemId
 #

   param (
      [string] $hashName,
      [string] $valueName
   )

   [xml] $doc = get-SQLDeveloperUserPreferencesXml

   $nameTable = new-object System.Xml.NameTable
   $nsMgr     = new-object System.Xml.XmlNamespaceManager $nameTable
   $nsMgr.AddNamespace('ide', 'http://xmlns.oracle.com/ide/hash')

   $value = $doc.SelectSingleNode('/ide:preferences/hash[@n="' + $hashName + '"]/value[@n="' + $valueName + '"]', $nsMgr)


   if ($value -eq $null) {
      return $null
   }
   return $value.GetAttribute('v')

}

function print-warning-unless-file-exists {
   param (
      [string] $supposedFileName
   )

   if ($supposedFileName) {
      if (! (test-path -pathType leaf $supposedFileName) ) {
         write-textInConsoleWarningColor "File $supposedFileName does not exist"
      }
   }
}

# }

# { get, set a setting

# { Font …

# { FontFamily

function get-SQLDeveloperFontFamily {
   return (get-preference FontSizeOptions fontFamily)
}

function set-SQLDeveloperFontFamily {

   param (
      [string] $newFontName
   )

   set-preference FontSizeOptions fontFamily $newFontName

}

# }

# { FontSize

function get-SQLDeveloperFontSize {
   return (get-preference FontSizeOptions fontSize)
}

function set-SQLDeveloperFontSize {

   param (
      [int] $newFontSize
   )

   set-preference FontSizeOptions fontSize $newFontSize

   <#

   $nameTable = new-object System.Xml.NameTable
   $nsMgr     = new-object System.Xml.XmlNamespaceManager $nameTable
   $nsMgr.AddNamespace('ide', 'http://xmlns.oracle.com/ide/hash')

   [xml] $doc = new-object xml

   $productPreferencesFile = "$(get-SQLDeveloperUserInformationDirectory)/o.sqldeveloper/product-preferences.xml"

   if (! (test-path $productPreferencesFile)) {
      write-textInConsoleErrorColor "product preference file $productPreferencesFile not found"
      return
   }
   $doc.Load($productPreferencesFile)

   $preferences = $doc.SelectSingleNode('/ide:preferences', $nsMgr)

 # $fontSizeOptions = $doc.SelectSingleNode('/ide:preferences/hash[@n="FontSizeOptions"]', $nsMgr)
   $hash_fontSizeOptions = $preferences.SelectSingleNode('hash[@n="FontSizeOptions"]', $nsMgr)
   if ($hash_fontSizeOptions -eq $null) {
      $hash_fontSizeOptions = $doc.CreateElement('hash')
      $hash_fontSizeOptions.SetAttribute('n', 'FontSizeOptions')
      $null = $preferences.AppendChild($hash_fontSizeOptions)
   }

   $value_fontSize = $hash_fontSizeOptions.SelectSingleNode('value[@n="fontSize"]')
   if ($value_fontSize -eq $null) {
      $value_fontSize = $doc.CreateElement('hash')
      $value_fontSize.SetAttribute('n', 'fontSize')
      $null = $hash_fontSizeOptions.AppendChild($value_fontSize)
   }

   $value_fontSize.SetAttribute('v', $newFontSize)

 #
 # Use Stream writer to control line ending:
 #
   $sw = new-object System.IO.StreamWriter $productPreferencesFile
   $sw.NewLine = "`n"

   $xw = new-object System.Xml.XmlTextWriter $sw
   $xw.Formatting  = 'Indented'
   $xw.IndentChar  = ' '
   $xw.Indentation = 3

   $doc.Save($xw)
   $sw.Close()

   #>

}
# }

# }
# { TNS_NAMES_directory

function set-SQLDeveloper_TNS_NAMES_directory {
   param (
      [string] $newValue
   )

 #
 # TODO: use print-warning-unless-file-exists to check for existence of directory
 #

   set-preference DBConfig TNS_NAMES_DIR $newValue

}

function get-SQLDeveloper_TNS_NAMES_directory {
   get-preference DBConfig TNS_NAMES_DIR
}

# }
# { NLS …
# { NLS_DATE_FORMAT

function set-SQLDeveloper_NLS_DATE_FORMAT {
   param (
      [string] $newFormat
   )

   set-preference DBConfig NLS_DATE_FORM $newFormat
}

function get-SQLDeveloper_NLS_DATE_FORMAT {
   get-preference DBConfig NLS_DATE_FORM
}

# }
# { NLS_TIMESTAMP_FORMAT

function set-SQLDeveloper_NLS_TIMESTAMP_FORMAT {
   param (
      [string] $newFormat
   )

   set-preference DBConfig NLS_TS_FORM $newFormat
}

function get-SQLDeveloper_NLS_TIMESTAMP_FORMAT {
   get-preference DBConfig NLS_TS_FORM
}

# }
# { NLS_TIMESTAMP_TZ_FORMAT

function set-SQLDeveloper_NLS_TIMESTAMP_TZ_FORMAT {
   param (
      [string] $newFormat
   )

   set-preference DBConfig NLS_TS_TZ_FORM $newFormat
}

function get-SQLDeveloper_NLS_TIMESTAMP_TZ_FORMAT {
   get-preference DBConfig NLS_TS_TZ_FORM
}

# }
# }
# { NULL…
# { NULL_text

function set-SQLDeveloper_NULL_text {
   param (
      [string] $newFormat
   )

   set-preference DBConfig NULLDISPLAY $newFormat
}

function get-SQLDeveloper_NULL_text {
   get-preference DBConfig NULLDISPLAY
}

# }
# { NULL_color

function set-SQLDeveloper_NULL_color {
   param (
      [string] $newValue
   )

   set-preference DBConfig NULLCOLOR $newValue
}

function get-SQLDeveloper_NULL_color {
   get-preference DBConfig NULLCOLOR
}

# }
# }
# { NewWorksheetConnection

function set-SQLDeveloperNewWorksheetConnection {
   param (
      [bool] $newValue
   )

   set-preference DBConfig UNSHAREDWORKSHEETOPEN $newValue
}

function get-SQLDeveloperNewWorksheetConnection {

   get-preference DBConfig UNSHAREDWORKSHEETOPEN
}

# }
# { glogin

function get-SQLDeveloper_glogin {
  (get-preference DBConfig GLOGIN) -eq 'true'
}

function set-SQLDeveloper_glogin {
   param (
      [boolean] $newValue
   )

#  if ($newValue) { $newValue_ = 'true' } else { $newValue_ = 'false'}

   set-preference DBConfig GLOGIN $newValue
}

# }
# { Startup Script

function get-SQLDeveloperStartupScript {
   return (get-preference DBConfig '')
}

function set-SQLDeveloperStartupScript {
   param (
      [string] $newValue
   )

   print-warning-unless-file-exists $newValue

   set-preference DBConfig '' $newValue
}

# }
# { UseThickDriver

function get-SQLDeveloperUseThickDriver {
   return (set-preference DBConfig USE_THICK_DRIVER)
}

function set-SQLDeveloperUseThickDriver {
   param (
      [bool] $newValue
   )
   set-preference DBConfig USE_THICK_DRIVER $newValue
}

# }
# { Kerberos …
# { KerberosThinConfigFile

function get-SQLDeveloperKerberosThinConfigFile {
   return (get-preference DBConfig KERBEROS_CONFIG)
}

function set-SQLDeveloperKerberosThinConfigFile {
   param (
      [string] $nevValue
   )

   print-warning-unless-file-exists $newValue
   set-preference DBConfig KERBEROS_CONFIG
}
# }
# { KerberosThinCredentialCache

function get-SQLDeveloperKerberosThinCredentialCache {
   return (get-preference DBConfig KERBEROS_CACHE)
}

function set-SQLDeveloperKerberosThinCredentialCache {
   param (
      [string] $nevValue
   )
   set-preference DBConfig KERBEROS_CACHE
}

# }
# }

# }
