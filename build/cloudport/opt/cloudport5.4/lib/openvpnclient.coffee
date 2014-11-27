@include = ->
#    cloud = require('./cloudflash')
#    cloudflash = new cloud(@include)
    exec = require('child_process').exec
    validate = require('json-schema').validate
    uuid = require('node-uuid')
    @db = db = require('dirty') '/opt/tmp/openvpnclient1.db'


#    @post '/openvpnclient/start', validateInput, ->
    @post '/openvpnclient/start' : ->
#         vpnc = {}
         vpnc = @body
         console.log vpnc.interval
         console.log "reached openvpnclient" 
#         exec '/usr/sbin/autogen.sh #{vpnc.interval} #{vpnc.times} &' , (error, stdout, stderr) =>
         exec "/usr/sbin/autogen.sh #{vpnc.interval} #{vpnc.times} &" , (error, stdout, stderr) =>
            if stderr or error
               console.log "#{stderr} \n ERROR #{error} "       
              # @send {status : false}
            console.log stdout 
         @send { status : true } 


      @get '/openvpnclient/status' : ->
          console.log "reached get status"
          status = 'unknown'
          exec '/usr/sbin/svcs.sh ' + "ovpnclient ", (error, stdout, stderr) =>
            if error or stderr
               console.log ".....stderr: #{stderr} ......error: #{error}"
            list = stdout.split "\n" 
            #console.log list
            status = "{\"status\":[#{list}"+"\"tunx : end\"]}" 
            @send status
          
      

    validateInput = ->
         console.log @body
         result = validate @body, clientdb
         console.log result
         return @next new Error "Invalid posting!: #{result.errors}" unless result.valid
         @next()


   clientdb=
        name: "clientdb"
        type: "object"
        additionalProperties: false
        properties:
          interval:    { type: "string", "required": true}
          times:  { type: "string", "required": true}

     @clientdb = clientdb

