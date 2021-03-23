#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: refresh_github_extract.bash <FQDN of DB Server> <DB Name> <DB User>"
    exit 1
fi

DBSERVER=$1
DBNAME=$2
DBUSER=$3

# read the contents of tables.sql into a variable
TABLES=$(<tables.sql)

# set internal bash separator to newline instead of default which is white space
IFS=$'\n'

# iterate over all sql statements in the tables.sql file
for sql in $TABLES

#TABLES=`echo "select table_name from information_schema.tables where table_schema = 'data';" | psql -t -h ${DBSERVER} ${DBNAME} ${DBUSER}`
do

    if [[ $sql == \#* ]]; then
        continue
    fi
    #echo "$sql" | grep -oP '.*:.*\b'
    table=`echo "$sql" | sed -r 's/(.*):\s+(.*)/\1/'`
    sql=`echo "$sql" | sed -r 's/(.*):\s+(.*)/\2/'`
    sqlcmd="${sql} copy (select * from tt ) to stdout with csv header; drop table tt;"
    
    # run sql and save to CSV file with headers intact
    echo "${sqlcmd}" | psql -q -t -h ${DBSERVER} ${DBNAME} ${DBUSER} > ./${table}.csv

    # generate definitions for the temporary tables represented by each of the queries so that someone can easily reproduce a working database
    sqlcmd="${sql} \d tt";
    rm ../sql_tables/${table}.sql
    echo "${sqlcmd}" | psql -q -h ${DBSERVER} ${DBNAME} ${DBUSER} | sed 's/Table .*/Table "'"${table}"'"/' > ../sql_tables/${table}.sql

    # compress the CSV in order to fit within github file size limits (100MB)
    zip -q ../data/${table}.zip ./${table}.csv
    rm ./${table}.csv
done

git add ../data
git add ../sql_tables
MSG="`/bin/date +\"%Y-%m-%d\"` data export"
echo $MSG
git commit -m ${MSG}
git push
