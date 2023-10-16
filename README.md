# PowerBIXeroConnector

This is the code for a simple PowerBI custom connector to the Xero API, using the Power Query SDK within VS Code.

You should be able to create a new extension project, copy in the code to your .pq file (making any adjustments to the connector name in the code), compile and run. Don't forget to overwrite the Client ID with your code from the Xero Developer Hub. 

If you encounter issues, I would recommend removing a lot of the steps in the XeroConnector function (basically everything after #"Expanded TB"), and compile that. Different entities may have slight differences in the TB setup that would cause one or more of the pre-programmed steps to fail.

If this is your first experience using PowerBI custom connectors, or connecting to the Xero API, I would recommend the following resources:

https://github.com/microsoft/DataConnectors

https://developer.xero.com/documentation/guides/oauth2/pkce-flow/

[Microsoft Power BI: Building connectors - BRK4003 - YouTube] https://www.youtube.com/watch?v=srQ-DLqhoxM

A video detailing the whole process from start to finish will follow.

If I have saved you lots of time and stress, please consider buying me a coffee :) 
(https://www.buymeacoffee.com/nickphillips)
