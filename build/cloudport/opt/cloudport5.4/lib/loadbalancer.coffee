##
# CLOUDFLASH /container REST end-points

@include = ->
    cloud = require('./cloudflash')
    cloudflash = new cloud(@include)
    exec = require('child_process').exec
    validate = require('json-schema').validate
    fileops = require 'fileops'
    uuid = require('node-uuid')
    @db = db = require('dirty') '/opt/tmp/loadbalancer.db'

    db.on 'load', ->
       console.log 'loaded loadbalance.db'
       db.forEach (key,val) ->
          console.log 'found ' + key


    # PUT VALIDATION
    # 1. need to make sure the incoming JSON is well formed
    # 2. destructure the inbound object with proper schema

     validateModuleDesc = ->
        console.log @body
        result = validate @body, loadbschema
        console.log result
        return @next new Error "Invalid config posting!: #{result.errors}" unless result.valid
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


    @configlb = configlb = (instance, filename, idb, callback) ->
        console.log 'idb is ' + idb
        service = "loadbalancer"
        config = ''
        for key, val of instance.config
            switch (typeof val)
                when "object"
                        for key2, val2 of val
                          for key3, val3 of val2
                            switch(typeof val3)
                                when "object"
                                       if val3 instanceof Array
                                            for i in val3
                                                  config += "#{key3} #{i}\n" if key3 is "server"
                                                  config += "#{key3} #{i}\n" if key3 is "stats"
                                when "number", "string"
                                          config += key3 + ' ' + val3 + "\n"
                                when "boolean"
                                          config += key3 + "\n"
                           config += "\n\n"
        console.log 'writing loadbalancer config onto file : ' + filename
        fileops.createFile filename, (result) ->
            callback(result) if result instanceof Error
#            return new Error "Unable to create configuration file #{filename}!" if result instanceof Error
            fileops.updateFile filename, config
            callback({service:true})



     @newobj = newobj =  (config) ->
        instance = {}
        instance.id = uuid.v4()
        instance.config = config
        #instance.config.id ?= uuid.v4()
        return instance



#body : command start, stop, vmon-start, vmon-stop 

    @post '/loadbalancer/action': ->
        status = 'action ' + @body.command
        switch @body.command
          when "stop","vmon-stop","restart","status"
#             console.log "Reached loadbalancer "	     
             exec '/usr/sbin/svcs.sh ' + "loadbalancer " + "#{@body.command}", (error, stdout, stderr) =>
                if error or stderr
                   console.log ".....stderr: #{stderr} ......error: #{error}"
                else
                   status = stdout
                   @send status
          when "start","vmon-start"
             exec '/usr/sbin/svcs.sh ' + "loadbalancer " + "#{@body.command}", (error, stdout, stderr) =>
                if error or stderr
                   console.log ".....stderr: #{stderr} ......error: #{error}"
                status = stdout
             @send { Status : "Accepted" }
          else return @next new Error "Invalid action, must specify 'command' (start|stop,restart,vmon-start|vmon-stop)!"
#             @next



#    @put '/loadbalancer/config': ->
#             status = 'action' + @body.command
#             exec '/usr/sbin/svcs.sh ' + "loadbalancer restart", (error, stdout, stderr) =>
#                if error or stderr
#                   console.log ".....stderr: #{stderr} ......error: #{error}"
#                 status = stdout
#                 @send status


    #@put '/loadbalancer/config', validateModuleDesc, ->
    @put '/loadbalancer/config' : ->
             instance = newobj @body
             status = 'action' + @body
             fname = "/opt/loadbalancer2.0/loadbalance.cfg" 
             configlb instance, fname, loadlb, (res) =>
                 unless res instanceof Error
                    console.log "filewrite over"
                  # exec '/usr/sbin/svcs.sh ' + "loadbalancer restart", (error, stdout, stderr) =>
                  #     if error or stderr
                  #          console.log ".....stderr: #{stderr} ......error: #{error}"
                  #          status = stdout  
                  #     else
                    @send instance.config 
                  else
                    @next new Error "Invalid LB Config posting! #{res}"



#    @get '/loadbalancer/status', loadModule, ->
    @get '/loadbalancer/status' : ->
#        loadb = @request.loadbalancer.db
#        console.log loaddb
        #console.log container.status
        status = 'Loadbalancer restarted with the new configuration'
        list = 'ddd'
#        console.log "angel svcs status"
        exec '/usr/sbin/svcs.sh ' + "loadbalancer status", (error, stdout, stderr) =>
            if error or stderr
               console.log ".....stderr: #{stderr} ......error: #{error}"
            list = stdout 
            #console.log list
            status = list  
            @send status
        @next








     loadlb =
        name: "loadb"
        type: "object"
        additionalProperties: false
        properties:
          class:    { type: "string" }
          id:      { type: "string" }
          name:      { type: "string", "required": true }
          memmax:    { type: "string", "required": true }
          memmin:    { type: "string", "required": true }
          status:    { type: "string" }

      @loadlb = loadlb

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

