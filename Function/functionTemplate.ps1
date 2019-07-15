<%
"function $PLASTER_PARAM_FunctionName"
%>
{
    <#
    .Synopsis
      Short description
    .DESCRIPTION
      Long description
    .EXAMPLE
      Example of how to use this cmdlet
    .NOTES
      Author: <%=$PLASTER_PARAM_FunctionAuthor%>
      Date: <%=$PLASTER_DATE%>
      Company: <%=$PLASTER_PARAM_Company%>
  #>

    [CmdletBinding()]
    param
    (
        # Parameter help description
        [Parameter(AttributeValues)]
        [ParameterType]
        $ParameterName
    )

}