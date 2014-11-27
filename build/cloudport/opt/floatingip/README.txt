config.ini

1. [initproperties] : This section is should there in the config.ini file. if this section is not there throw
                      the error and exit form the script.
2. In [initproperties] this section we have input_dir, output_dir parameters. if these parameter is provided it will take the
   input from the path and write the output into corresponding path else it will look for input directory in current
   directory and takes the input.
3. [general] : This selction for test cases. we can give any names like test, test1 etc.., if we want to write more test cases
               create more sections like this, this section name sould be unique.
4. In [general] section we have "url, page, content, content_file, method, result_console, result_file" these parameters
   --url: mesion name ,IP address, or url 
        ex:192.12.1.188 or www.python.org
   --page : Landing page
        ex: 192.12.1.188/services here we need to give "services" 
            www.python.org/index.html here we need to give "index.html"
   --content: content for input as a string
   --content_file: if we want to give content as file, if u provide both content and content_file, by default it will takes
                   file, if we want to run same file multiple time "filename space 2" it will twice with same file. if u are
                   not provide the number of time it will takes as 1.
                   ex: filename.ext 2 , filename.ext , filename.ext 3
  --method: Ex: POST, GET,
  --result_console: If it is True, Result print in screen
  --result_file : If it is True, Result writes in file
