#!/bin/bash
DB_USER="us"
DB_NAME="db"

read -r POST_STRING

username=`echo $POST_STRING | awk -F'[=&]' '{print $2}'`
password=`echo $POST_STRING | awk -F'[=&]' '{print $4}'`

echo "Content-type: text/html"
echo ""
echo "<html><head>"

if [ ${#username} -lt 6 ]
then
cat <<EOT
<title></title>
</head>
<body>
<h1>Your username must have at least 6 characters!</h1>
EOT
elif [ ${#password} -lt 8 ]
then
cat <<EOT
<title></title>
</head>
<body>
<h1>Your password must have at least 8 characters!</h1>
EOT
else
    if [ -n $(mysql -Ns -u "$DB_USER" -e "SELECT * FROM LoginInfo WHERE Username='$username'" "$DB_NAME";) ]
    then
        mysql -u "$DB_USER" -e "INSERT INTO LoginInfo(Username, Password) VALUES ('$username', '$password')" "$DB_NAME";
        cat <<EOT
<title></title>
</head>
<body>
<h1>Account created successfuly!</h1>
EOT
    else
    cat <<EOT
<title></title>
</head>
<body>
<h1>There already exists an account with this username!</h1>
EOT
fi
fi

echo "</body></html>"
