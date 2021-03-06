##
# CLOUDFLASH /modules REST end-points

@include = ->
    cloud = require('./cloudflash')
    cloudflash = new cloud(@include)
    exec = require('child_process').exec

    @get '/modules': ->
        res = cloudflash.list()
        console.log res
        @send res

    # POST/PUT VALIDATION
    # 1. need to make sure the incoming JSON is well formed
    # 2. destructure the inbound object with proper schema
    validateModuleDesc = ->
        console.log @body
        result = cloudflash.validate @body
        console.log result
        return @next new Error "Invalid module posting!: #{result.errors}" unless result.valid
        @next()

    # helper routine for retrieving module data from dirty db
    loadModule = ->
        result = cloudflash.lookup @params.id
        unless result instanceof Error
            @request.module = result
            @next()
        else
            return @next result

    @post '/modules', validateModuleDesc, ->
        module = cloudflash.new @body
        cloudflash.add module, (error) =>
            unless error
                console.log module
                if module.status.installed
                  console.log 'inside modules.coffee/post modules'
                  @send module
                else
                  @send 304
            else
                @next error


    @get '/modules/:id', loadModule, ->
        module = @request.module

        installed = null
        if module.status
            installed = true
        status =
            installed: installed ? false
            initialized: false
            #enabled: false
            #running: false
            result: 'unknown'

        exec "/usr/sbin/svcs.sh #{module.description.name} status", (error, stdout, stderr) =>
            if error or stderr
               status.result =  '' + error
            else
                if stdout.match /disabled/
                    status.initialized = true
                else if stdout.match /enabled/
                    status.enabled = true
                    unless stdout.match /not running/
                        status.running = true

                status.result = stdout
 
            module.status = status

            console.log module
            @send module


    @put '/modules/:id', validateModuleDesc, loadModule, ->
        # XXX - can have intelligent merge here

        # PUT VALIDATION
        # 1. need to make sure the incoming JSON is well formed
        # 2. destructure the inbound object with proper schema
        # 3. perform 'extend' merge of inbound module data with existing data
        module = @request.module

        # desc = @body
        # @body = entry
        # @body.description ?= desc if desc?

        cloudflash.db.set module.id, module, =>
            console.log "updated module ID: #{module.id}"
            console.log module
            @send module
            # do some work

    @del '/modules/:id', loadModule, ->
        # 1. verify that the package is actually installed
        # 2. perform dpkg -r PACKAGENAME
        # 3. remove the module entry from DB
        cloudflash.remove @request.module, (error) =>
            unless error
                @send { deleted: true }
            else
                @next error

    @post '/modules/:id/action', loadModule, ->
        return @next new Error "Invalid module posting!" unless @body.command
        module = @request.module
        desc = module.description

        console.log "looking to issue 'svcs #{desc.name} #{@body.command}'"
        switch @body.command
            when "on", "off", "stop","restart","status","sync", "vmon-stop"
                exec "/usr/sbin/svcs.sh #{desc.name} #{@body.command}", (error, stdout, stderr) =>
                #exec "pwd", (error, stdout, stderr) =>
                    if error or stderr
                       console.log ".....stderr: #{stderr} ......error: #{error}"
                       @next 
                     #return @next new Error "Unable to perform requested action!" if error
                    #@send { result: true }
                    else
                       @send stdout
            when "start", "vmon-start"
               exec "/usr/sbin/svcs.sh #{desc.name} #{@body.command}", (error, stdout, stderr) =>
                #exec "pwd", (error, stdout, stderr) =>
                    if error or stderr
                       console.log ".....stderr: #{stderr} ......error: #{error}"
                       @next
                     #return @next new Error "Unable to perform requested action!" if error
                    #@send { result: true }
                @send { Status : "Accepted" }
            else return @next new Error "Invalid action, must specify 'command' (on|off,start|stop,restart,sync)!"

    ##
    # TEST ENDPOINTS

    @get '/test/modules': ->
        cloudflash.list()

        module = cloudflash.lookup 'helloworld'
        console.log module

        module = cloudflash.new {
            version: '1.0'
            name: 'at'
            family: 'remote-access'
            pkgurl: 'http://10.1.10.145/vpnrac-0.0.1.deb'
        }

        cloudflash.add module, (error) =>
            unless error
                console.log 'added successfully'
                @send module
            else
                console.log 'adding failed'
                @next error

