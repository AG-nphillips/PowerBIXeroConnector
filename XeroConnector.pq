// This file contains your Data Connector logic
[Version = "1.0.0"]
section XeroConnector;

[DataSource.Kind="XeroConnector", Publish="XeroConnector.Publish"]
shared XeroConnector.Contents = (date) =>
    let
        Source = Json.Document(Web.Contents(connections_uri, [Headers = [#"Accept" = "application/json"]])), 
        #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "authEventId", "tenantId", "tenantType", "tenantName", "createdDateUtc", "updatedDateUtc"}, {"id", "authEventId", "tenantId", "tenantType", "tenantName", "createdDateUtc", "updatedDateUtc"}),
        #"Removed Other Columns" = Table.SelectColumns(#"Expanded Column1",{"tenantId", "tenantName"}),
        #"Added Custom" = Table.AddColumn(#"Removed Other Columns", "Month", each date),
        #"Added Custom1" = Table.AddColumn(#"Added Custom", "TB", each XeroTrialBalance([tenantId], [Month])),
        #"Expanded TB" = Table.ExpandTableColumn(#"Added Custom1", "TB", {"Name", "Value"}, {"Name", "Value"}),
        #"Filtered Rows" = Table.SelectRows(#"Expanded TB", each ([Name] = "Reports")),
        #"Expanded Value" = Table.ExpandListColumn(#"Filtered Rows", "Value"),  
        #"Expanded Reports1" = Table.ExpandRecordColumn(#"Expanded Value", "Value", {"Fields", "Rows"}, {"Fields", "Rows"}),
        #"Expanded Rows" = Table.ExpandListColumn(#"Expanded Reports1", "Rows"),
        #"Expanded Fields" = Table.ExpandListColumn(#"Expanded Rows", "Fields"),
        #"Expanded Rows1" = Table.ExpandRecordColumn(#"Expanded Fields", "Rows", {"RowType", "Cells", "Title", "Rows"}, {"RowType", "Cells", "Title", "Rows.1"}),
        #"Expanded Rows.1" = Table.ExpandListColumn(#"Expanded Rows1", "Rows.1"),
        #"Expanded Rows.2" = Table.ExpandRecordColumn(#"Expanded Rows.1", "Rows.1", {"Cells"}, {"Cells.1"}),
        #"Expanded Cells.1" = Table.ExpandListColumn(#"Expanded Rows.2", "Cells.1"),
        #"Expanded Cells.2" = Table.ExpandRecordColumn(#"Expanded Cells.1", "Cells.1", {"Value", "Attributes"}, {"Value", "Attributes"}),
        #"Expanded Attributes" = Table.ExpandListColumn(#"Expanded Cells.2", "Attributes"),
        #"Expanded Attributes1" = Table.ExpandRecordColumn(#"Expanded Attributes", "Attributes", {"Value", "Id"}, {"Value.1", "Id"}),
        #"Expanded Cells" = Table.ExpandListColumn(#"Expanded Attributes1", "Cells"),
        #"Expanded Cells1" = Table.ExpandRecordColumn(#"Expanded Cells", "Cells", {"Value"}, {"Value.2"}),
        #"Removed Columns" = Table.RemoveColumns(#"Expanded Cells1",{"Fields", "RowType", "Value.1", "Id"}),
        #"Added Index" = Table.AddIndexColumn(#"Removed Columns", "Index", 0, 1, Int64.Type),
        #"Inserted Modulo" = Table.AddColumn(#"Added Index", "Modulo", each Number.Mod([Index], 5), type number),
        #"Added Custom2" = Table.AddColumn(#"Inserted Modulo", "Header", each if [Modulo] = 0 then "Account" else if [Modulo] = 1 then "Debit" else if [Modulo] = 2 then "Credit" else if [Modulo] = 3 then "YTD Debit" else "YTD Credit"),
        #"Pivoted Column" = Table.Pivot(#"Added Custom2", List.Distinct(#"Added Custom2"[Header]), "Header", "Value"),
        #"Filled Up" = Table.FillUp(#"Pivoted Column",{"Debit", "Credit", "YTD Debit", "YTD Credit"}),
        #"Filtered Rows1" = Table.SelectRows(#"Filled Up", each ([Account] <> null and [Account] <> "" and [Account] <> "0.00" and [Account] <> "22521.66")),
        #"Changed Type" = Table.TransformColumnTypes(#"Filtered Rows1",{{"Debit", type number}, {"Credit", type number}, {"YTD Debit", type number}, {"YTD Credit", type number}}),
        #"Replaced Value" = Table.ReplaceValue(#"Changed Type",null,0,Replacer.ReplaceValue,{"Debit", "Credit", "YTD Debit", "YTD Credit"}),
        #"Removed Columns1" = Table.RemoveColumns(#"Replaced Value",{"Value.2", "Index", "Modulo"}),
        #"Inserted Text Between Delimiters" = Table.AddColumn(#"Removed Columns1", "Text Between Delimiters", each Text.BetweenDelimiters([Account], "(", ")"), type text),
        #"Reordered Columns" = Table.ReorderColumns(#"Inserted Text Between Delimiters",{"tenantId", "tenantName", "Month", "Title", "Account", "Text Between Delimiters", "Debit", "Credit", "YTD Debit", "YTD Credit"}),
        #"Renamed Columns" = Table.RenameColumns(#"Reordered Columns",{{"Text Between Delimiters", "Code"}}),
        #"Changed Type1" = Table.TransformColumnTypes(#"Renamed Columns",{{"Code", Int64.Type}}),
        #"Sorted Rows" = Table.Sort(#"Changed Type1",{{"Code", Order.Ascending}}),
        #"Inserted Subtraction" = Table.AddColumn(#"Sorted Rows", "Subtraction", each [Debit] - [Credit], type number),
        #"Renamed Columns1" = Table.RenameColumns(#"Inserted Subtraction",{{"Subtraction", "Value MTD"}}),
        #"Inserted Subtraction1" = Table.AddColumn(#"Renamed Columns1", "Subtraction", each [YTD Debit] - [YTD Credit], type number),
        #"Renamed Columns2" = Table.RenameColumns(#"Inserted Subtraction1",{{"Subtraction", "Value YTD"}}),
        #"Removed Columns2" = Table.RemoveColumns(#"Renamed Columns2",{"Debit", "Credit", "YTD Debit", "YTD Credit", "tenantId"})
        
    in
        #"Removed Columns2";
    

shared XeroTrialBalance = (tenant, date) =>
    let
        TB = Json.Document(Web.Contents(trial_balance_uri & "?date="& date, [Headers = [#"xero-tenant-id" = tenant, #"Accept"="application/json"]])),
        #"Converted to Table" = Record.ToTable(TB)
    in
        #"Converted to Table";

// Standing Data
xero_login_url = "https://login.xero.com/identity/connect";
scopes = "offline_access openid profile email accounting.transactions accounting.settings accounting.contacts accounting.reports.read";
redirect_uri = "https://oauth.powerbi.com/views/oauthredirect.html";
logout_uri = "https://login.microsoftonline.com/logout.srf";
client_id = "YOUR_CLIENT_ID";
token_uri = "https://identity.xero.com/connect/token";
connections_uri = "https://api.xero.com/connections";
codeVerifier = Text.NewGuid() & Text.NewGuid();
trial_balance_uri = "https://api.xero.com/api.xro/2.0/Reports/TrialBalance";

// Crypto Hashing function
Base64UrlEncodeWithoutPadding = (hash as binary) as text =>
    let
        base64Encoded = Binary.ToText(hash, BinaryEncoding.Base64),
        base64UrlEncoded = Text.Replace(Text.Replace(base64Encoded, "+", "-"), "/", "_"),
        withoutPadding = Text.TrimEnd(base64UrlEncoded, "=")
    in 
        withoutPadding;

// Login Functions
StartLogin = (resourceUrl, state, display) =>
    let
        // We'll generate our code verifier using Guids
        CodeChallenge = Base64UrlEncodeWithoutPadding(Crypto.CreateHash(CryptoAlgorithm.SHA256, Text.ToBinary(codeVerifier, TextEncoding.Ascii))),
        AuthorizeUrl = xero_login_url
            & "/authorize?"
            & Uri.BuildQueryString(
                [
                    response_type = "code",
                    client_id = client_id,
                    redirect_uri = redirect_uri,
                    scope = scopes,
                    state = "123",
                    code_challenge = CodeChallenge,
                    code_challenge_method = "S256"   
                ]
            )
    in
        [
            LoginUri = AuthorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = 1024,
            WindowWidth = 768,
            context = []           
        ];

FinishLogin = (context, CallbackUri, state) =>
    let
        Parts = Uri.Parts(CallbackUri)[Query]

    in
        TokenMethod("authorization_code", "code", Parts[code]);


TokenMethod = (grant_type, tokenField, code) =>
    let
        queryString = [
            grant_type = grant_type,
            redirect_uri = redirect_uri,
            client_id = client_id,
            code_verifier = codeVerifier
        ],
        queryWithCode = Record.AddField(queryString, tokenField, code),
        
        // Set this if your API returns a non-2xx status for login failures
        // ManualHandlingStatusCodes = {400, 403}
        ManualHandlingStatusCodes = {400, 403},
        Response = Web.Contents(token_uri,
            [
                Content = Text.ToBinary(Uri.BuildQueryString(queryWithCode)),
                Headers = [
                    #"Content-type" = "application/x-www-form-urlencoded",
                    #"Accept" = "application/json"
                    ],
                ManualStatusHandling = ManualHandlingStatusCodes
            ]
        ),
        Parts = Json.Document(Response)
    in
        // check for error in response
        if (Parts[error]? <> null) then
            error Error.Record(Parts[error], Parts[message]?)
        else
            Parts;

Refresh = (resourceUrl, refresh_token) => 
let 
    result = TokenMethod("refresh_token", "refresh_token", refresh_token)
in
    result;


// Data Source Kind description
XeroConnector = [
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Refresh = Refresh        
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
XeroConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = XeroConnector.Icons,
    SourceTypeImage = XeroConnector.Icons
];

XeroConnector.Icons = [
    Icon16 = { Extension.Contents("XeroConnector16.png"), Extension.Contents("XeroConnector20.png"), Extension.Contents("XeroConnector24.png"), Extension.Contents("XeroConnector32.png") },
    Icon32 = { Extension.Contents("XeroConnector32.png"), Extension.Contents("XeroConnector40.png"), Extension.Contents("XeroConnector48.png"), Extension.Contents("XeroConnector64.png") }
];
