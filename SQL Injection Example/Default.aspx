<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="CS" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <style type="text/css">
        body
        {
            font-family: Arial;
            font-size: 10pt;
        }
        table
        {
            border:1px solid #ccc;
            border-collapse:collapse;
        }
        table th
        {
            background-color: #F7F7F7;
            color: #333;
            font-weight: bold;
        }
        table th, table td
        {
            padding: 5px;
            border-color: #ccc;
        }
	#SearchLastName
	{
		display: block;
		width: 75%;
	}
    </style>
</head>
<body>
<h1>Client Database Search</h1>
    <form id="form1" runat="server">
	<p>Last name search: <asp:TextBox ID="SearchLastName" runat="server"></asp:TextBox></p>
	<p><asp:Button ID="SubmitSearch" runat="server" Text="Search" /></p>

	<p><asp:PlaceHolder  ID = "PlaceHolder1" runat="server" /></p>
	
    </form>
</body>
</html>
