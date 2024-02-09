#!/bin/bash
DB_USER="us"
DB_NAME="db"

location=`echo $QUERY_STRING | awk -F'[=&]' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr '+' '-'`
number=`echo $QUERY_STRING | awk -F'[=&]' '{print $4}' | tr -d '+'`
search=`echo $QUERY_STRING | awk -F'[=&]' '{print $6}'`
id=`echo $QUERY_STRING | awk -F'[=&]' '{print $8}'`


if [ $search = "houses" ]
then
link="https://www.olx.ro/imobiliare/case-de-vanzare/"
elif [ $search = "apartments" ]
then
link="https://www.olx.ro/imobiliare/apartamente-garsoniere-de-vanzare/"
fi

echo "Content-type: text/html"
echo ""
echo "<html><head>"

#check if any of the form fields are empty; if so, it will return an error
if [ -z $location ] || [ -z $number ] || ! [[ $number =~ ^[0-9]+$ ]] || [ -z $search ] || [ -z $id ] || [ -z $(mysql -Ns -u "$DB_USER" -e "SELECT ID FROM LoginInfo WHERE ID=$id" "$DB_NAME";) ]
then
cat <<EOT
<title>Error!</title>
</head>
<body>
<h1>Invalid search query!</h1>
EOT
if [ -n $(mysql -Ns -u "$DB_USER" -e "SELECT ID FROM LoginInfo WHERE ID=$id" "$DB_NAME";) ] #furthermore, we check if the issue is cause by an incorrect user code, instead of the fields from the form
then
echo "<h4>Reason: The user does not exist!</h4>"
fi
else #if the query is correct, the scraping takes place
cat <<EOT
<title>Search result</title>
</head>
EOT

    link="$link$location/?currency=EUR"
    if ! [ -z $(curl -s "$link" | grep -oP '<h3 class="c-container__title">Pagina cautata nu a fost gasita</h3>') ]
    #check if the query generates a valid link; if not, the user entered an invalid location
    then
        echo "<h1>Invalid location!</h1>"
    else
        max_page=`curl -s "$link" | grep -oP '(?<=<a data-testid="pagination-link-)[^"]*' | sort -nr | head -n 1`
        results=`curl -s "$link" | grep -oP '(?<=<span data-testid="total-count">)[^<]*' | grep -oP '\d+'`
        if  [ -z $results ]
        then
        results=`curl -s "$link" | grep -oP '(?<=<span data-testid="total-count">Am găsit <span>peste</span> ).*(?= rezultate pentru tine</span>)' | sed 's/\.//g'`
        fi
            if [ "$results" -eq "0" ]
            then
                echo "<h3>Unfortunately, there are no results for this housing choice and location. Please choose another</h3>"
            else
                true_results=0
                total_value=0
                min_results=$(( number<results ? number : results ))
                for i in `seq 1 $max_page`; do
                 if [ $true_results -eq $min_results ]
                then
                    break
                fi
                if [ $i -eq 1 ]
                then
                prices_array=($(curl -s "$link" | grep -oP '(?<=<p data-testid="ad-price" class="css-10b0gli er34gjf0">)[^<]*' | sed 's/ €//g' | tr -d ' '))
                else
                prices_array=($(curl -s "$link&page=$i" | grep -oP '(?<=<p data-testid="ad-price" class="css-10b0gli er34gjf0">)[^<]*' | sed 's/ €//g' | tr -d ' '))
                fi
                for price in "${prices_array[@]}"; do
                    if [ $true_results -lt $min_results ]
                    then
                        ((total_value+=$price))
                    else
                        break
                    fi
                    ((true_results++))
done
done
                echo "<h1>The average price for the area and housing you chose is $(( total_value/min_results )) &#x20AC based on $min_results results.</h1>"
                mysql -u "$DB_USER" -e "INSERT INTO Searches(Location, Housing, User, Average, Pool) VALUES('$(echo $location | tr '[:lower:]' '[:upper:]')', '$search', '$id', '$(( total_value/min_results ))', '$min_results')" "$DB_NAME";
                cat <<EOT
<form action="search.sh" method="GET">
<input type="hidden" name="ID" value="$id">
<input type="submit" value="Search again">
</form>
EOT
            fi
    fi
fi

echo "</body></html>"

