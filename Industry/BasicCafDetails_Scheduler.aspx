<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="BasicCafDetails_Scheduler.aspx.cs" Inherits="CEIHaryana.Industry.BasicCafDetails_Scheduler" %>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <asp:HiddenField ID="hfTaskCompleted" runat="server" Value="false" />
    </form>
    <script type="text/javascript">
        window.onload = function () {
            var taskCompleted = document.getElementById('<%= hfTaskCompleted.ClientID %>').value;
            if (taskCompleted === "true") {
                window.open('', '_self', '');
                window.close();
            }
        };
    </script>
</body>
</html>
