#!/bin/bash
DB_USER="us"
DB_NAME="db"

echo "Content-type: text/html"
echo ""

id=`echo $QUERY_STRING | awk -F'=' '{print $2}'`
user_check=`mysql -Ns -u "$DB_USER" -e "SELECT ID FROM LoginInfo WHERE ID='$id'" "$DB_NAME"`

echo "<html><head>"
echo "<style>"
echo "table, th, td {"
echo "border:1px solid black; text-align:center;}</style>"


if [ -z $id ]
then
cat <<EOT
<title>You must be logged in!</title>
</head>
<body>
<h1>You must be logged in to perform this operation!</h1>
<form action="../index.html" method="GET">
<input type="submit" value="Login">
</form>
EOT
else
    if [ -z $user_check ]
    then
cat <<EOT
<title>Error</title>
</head>
<body>
<h1>This user does not exist!</h1>
EOT
    else
cat <<EOT
<title>Search</title>
</head>
<body>
<h1>Housing average calculator</h1>
<form action="searchdata.sh" method="GET">
    <h3>Location</h3>
    <input type="text" name="location">
    <br>
    <h3>How many result would you like to be processed?</h3>
    <input type="number" name="number" min="1" max="1000">
    <h3>What are you looking for?</h3>
    <input type="radio" name="search" value="houses">
    <label for="houses">Houses</label>
    <br>
    <input type="radio" name="search" value="apartments">
    <label for="apartments">Apartments</label>
    <input type="hidden" name="id" value="$id">
    <br>
    <input type="submit" value="Search">
</form>
<br>
<br>
<br>
<h2>Most frequently searched locations</h2>
<ul>
EOT
most_freq_arr=($(mysql -Ns -u "$DB_USER" -e "SELECT COUNT(Location), Location FROM Searches GROUP BY Location ORDER BY COUNT(Location) DESC LIMIT 3;" "$DB_NAME"))
i=1;
while [ $i -lt ${#most_freq_arr[@]} ]; do
echo "<li>$( echo "${most_freq_arr[$i]}" | tr '-' ' ')</li>"
i=$(( $i + 2 ))
done
cat <<EOT
</ul>
<h2>Last searched locations</h2>
<table>
<tr>
<th>Location</th>
<th>Housing type</th>
<th>Average Price</th>
<th>Ad Pool</th>
</tr>
<tr>
EOT
last_search_arr=($(mysql -Ns -u "$DB_USER" -e "SELECT Location, Housing, Average, Pool FROM Searches ORDER BY ID DESC LIMIT 3;" "$DB_NAME";))
i=0;
while [ $i -lt ${#last_search_arr[@]} ]; do
    echo "<td>$( echo "${last_search_arr[$i]}" | tr '-' ' ')</td>"
    if [ $((i%4)) -eq 3 ] && [ $i -ne 0 ]
    then
    echo "</tr><tr>"
    fi
    ((i++))
done
fi
fi

echo "</table></body></html>"
