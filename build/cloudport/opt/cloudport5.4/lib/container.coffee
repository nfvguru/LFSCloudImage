##
# CLOUDFLASH /container REST end-points

@include = ->
    cloud = require('./cloudflash')
    cloudflash = new cloud(@include)
    exec = require('child_process').exec
    validate = require('json-schema').validate
    uuid = require('node-uuid')
    @db = db = require('dirty') '/opt/tmp/container.db'

    db.on 'load', ->
       console.log 'loaded container.db'
       db.forEach (key,val) ->
          console.log 'found ' + key


    @get '/container': ->
        res = ' '
        res = list()
        console.log res
        @send res

    

    # POST/PUT VALIDATION
    # 1. need to make sure the incoming JSON is well formed
    # 2. destructure the inbound object with proper schema

     validateModuleDesc = ->
        console.log @body
        result = validate @body, containerschema
        console.log result
        return @next new Error "Invalid module posting!: #{result.errors}" unless result.valid
        @next()

    # helper routine for retrieving module data from dirty db
    loadModule = ->
        console.log "loadModule #{@params.id}"
        result = lookup @params.id
        unless result instanceof Error
            @request.container = result
            @next()
        else
            return @next result


    @get '/container/:id', loadModule, ->
          console.log "get id................"
          container = @request.container
          console.log container
          status = 'unknown'
          console.log "angel svcs #{container.name} status"
          exec '/usr/sbin/svcs.sh ' + "container all", (error, stdout, stderr) =>
            if error or stderr
                console.log ".....stderr: #{stderr} ......error: #{error}"
            else
                if stdout.match /mem_size/
                    status = "{\n \"id\" : \"#{container.id}\", \n #{stdout}}"
              @send status		

    @post '/container', validateModuleDesc, ->
#    @post '/container': ->
         container = cloudflash.newc @body
#         console.log container
         console.log "[post /container]calling add"
         add container, (error) =>
            unless error
                console.log "[post /container]unless error.."
                console.log container
                @send container 
            else
                console.log "[post/container]..else....."
            #    @next error
                @next

         
    @get '/container/:id/memoryusage', loadModule, ->
        container = @request.container
        console.log container
        #console.log container.status
        status = 'unknown'
        console.log "angel svcs #{container.name} status"
        exec '/usr/sbin/svcs.sh ' + "container memusage", (error, stdout, stderr) =>
            if error or stderr
               console.log ".....stderr: #{stderr} ......error: #{error}"
            else
                if stdout.match /memusage/
                    status = stdout 

            container.status = status
            console.log container 
            @send container

    @get '/container/:id/cpuusage', loadModule, ->
        container = @request.container
        console.log container
        #console.log container.status
        status = 'unknown'
        console.log "angel svcs #{container.name} status"
        exec '/usr/sbin/svcs.sh ' + "container cpuusage", (error, stdout, stderr) =>
            if error or stderr
               console.log ".....stderr: #{stderr} ......error: #{error}"
            else
                if stdout.match /cpuusage/
                    status = stdout

            container.status = status
            console.log container
            @send container

    @get '/container/:id/remediation' : ->
             console.log "asdasd"
             status =
                loadbalancer: false
                sslacceleration: false
                vpn: false
              exec '/usr/sbin/remediation.sh ' , (error, stdout, stderr) =>
                     if error or stderr
                       console.log error
                       console.log stderr
                     else
                      if stdout
                          if stdout.match /loadbalancer/
                               status.loadbalancer = true
                          else if stdout.match /sslacceleration/
                               status.sslacceleration = true
                          else if stdout.match /openvpn/
                               status.vpn = true
                          console.log status
                         @send status



     @post '/container/shutdown' : ->
             status = 'Status : shutdown'
             exec '/usr/sbin/svcs.sh ' + "container shutdown", (error, stdout, stderr) =>
                if error or stderr
                   console.log ".....stderr: #{stderr} ......error: #{error}"
                 status = stdout
                @send status



    @post '/container/:id/shutdown', loadModule, ->
        container = @request.container
        console.log container
        #console.log container.status
        status = 'shutdown'
        console.log "angel svcs #{container.name} status"
        exec '/usr/sbin/svcs.sh ' + "container shutdown", (error, stdout, stderr) =>
            if error or stderr
               console.log ".....stderr: #{stderr} ......error: #{error}"

            container.status = stdout
            console.log container
            @send container



    @put '/container/:id', validateModuleDesc, loadModule, ->
        # XXX - can have intelligent merge here

        # PUT VALIDATION
        # 1. need to make sure the incoming JSON is well formed
        # 2. destructure the inbound object with proper schema
        # 3. perform 'extend' merge of inbound module data with existing data
             rec = cloudflash.newc @body
             container = @request.container
             rec.id = container.id
             console.log container 

#             db.set container.id, container, =>
             db.set container.id, rec, =>
             console.log "updated module ID: #{module.id}"
             console.log container
             @send rec
            # do some work

     containerschema =
        name: "container"
        type: "object"
        additionalProperties: false
        properties:
          class:    { type: "string" }
          id:      { type: "string" }
          name:      { type: "string", "required": true }
          memmax:    { type: "string", "required": true }
          memmin:    { type: "string", "required": true }
          status:    { type: "string" }

      @containerschema = containerschema

      @lookup = lookup = (id) ->
             console.log "looking up user ID: #{id}"
             entry = db.get id
             if entry
                 if containerschema?
                      console.log 'performing schema validation on retrieved user entry'
                      result = validate entry, containerschema
                      console.log result
                      return new Error "Invalid user retrieved: #{result.errors}" unless result.valid
                  return entry
             else
                return new Error "No such module ID: #{id}"



      @add = add = (component, callback) ->
         console.log "inside add function"
#         id = uuid.v4()
         console.log  component
         try
            db.set component.id, component, ->
             #  console.log "Added to the database"
             callback()
         catch err
            console.log "caught error"
            callback(err)

      @list = list = ->
         console.log "looking up list}"
         res = { 'container': [] }
         if res
           db.forEach (key,val) ->
             console.log 'found ' + key
             res.container.push val
         console.log 'listing...'
         return res

