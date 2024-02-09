#!/bin/bash
DB_USER="us"
DB_NAME="db"

read -r POST_STRING

username=`echo $POST_STRING | awk -F'[=&]' '{print $2}'`
password=`echo $POST_STRING | awk -F'[=&]' '{print $4}'`

echo "Content-type: text/html"
echo ""
echo "<html><head>"

userid=`mysql -Ns -u "$DB_USER" -e "SELECT ID FROM LoginInfo WHERE Username='$username' AND Password='$password'" "$DB_NAME"`

if [ -z $userid ]
then
cat <<EOT
<title>Login error</title>
</head>
<body>
<h1>Incorrect username and password combination! Try again</h1>
<form action="/index.html">
<input type="submit" value="Return to login">
</form>
EOT
else
cat <<EOT
<title>Successful operation!</title>
</head>
<body>
<h1>Successfully logged in!</h1>
<form action="search.sh" method="GET">
<input type="hidden" name="ID" value="$userid">
<input type="submit" value="Go to search page!">
</form>
EOT
fi

echo "</body></html>"
