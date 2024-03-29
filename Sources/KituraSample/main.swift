/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

// KituraSample shows examples for creating custom routes.

import KituraSys
import KituraNet
import KituraRouter

import LoggerAPI
import HeliumLogger

#if os(Linux)
    import Glibc
#endif

import Foundation

import KituraStencil


// All Web apps need a router to define routes
let router = Router()

// Using an implementation for a Logger
Log.logger = HeliumLogger()

/**
* RouterMiddleware can be used for intercepting requests and handling custom behavior
* such as authentication and other routing
*/
class BasicAuthMiddleware: RouterMiddleware {
    func handle(request: RouterRequest, response: RouterResponse, next: () -> Void) {

        let authString = request.headers["Authorization"]

        Log.info("Authorization: \(authString)")

        next()
        // Check authorization string in database to approve the request if fail
        // response.error = NSError(domain: "AuthFailure", code: 1, userInfo: [:])
       
        next()
    }
}


// This route executes the echo middleware
router.use("/*", middleware: BasicAuthMiddleware())

router.use("/static/*", middleware: StaticFileServer())

router.get("/hello") { _, response, next in
     response.setHeader("Content-Type", value: "text/plain; charset=utf-8")
     do {
         try response.status(HttpStatusCode.OK).send("Hello World, from Kitura!").end()
     }
     catch {}
     next()
}

// This route accepts POST requests
router.post("/hello") {request, response, next in
    response.setHeader("Content-Type", value: "text/plain; charset=utf-8")
    do {
        try response.status(HttpStatusCode.OK).send("Got a POST request").end()
    }
    catch {}
    next()
}

// This route accepts PUT requests
router.put("/hello") {request, response, next in
    response.setHeader("Content-Type", value: "text/plain; charset=utf-8")
    do {
        try response.status(HttpStatusCode.OK).send("Got a PUT request").end()
    }
    catch {}
    next()
}

// This route accepts DELETE requests
router.delete("/hello") {request, response, next in
    response.setHeader("Content-Type", value: "text/plain; charset=utf-8")
    do {
        try response.status(HttpStatusCode.OK).send("Got a DELETE request").end()
    }
    catch {}
    next()
}

// Error handling example
router.get("/error") { _, response, next in
    Log.error("Example of error being set")
    response.status(HttpStatusCode.INTERNAL_SERVER_ERROR)
    response.error = NSError(domain: "RouterTestDomain", code: 1, userInfo: [:])
    next()
}

// Redirection example
router.get("/redir") { _, response, next in
    do {
        try response.redirect("http://www.ibm.com")
    }
    catch {}

    next()
}

// Reading parameters
// Accepts user as a parameter
router.get("/users/:user") { request, response, next in
    response.setHeader("Content-Type", value: "text/html; charset=utf-8")
    let p1 = request.params["user"] ?? "(nil)"
    do {
        try response.status(HttpStatusCode.OK).send(
            "<!DOCTYPE html><html><body>" +
            "<b>User:</b> \(p1)" +
            "</body></html>\n\n").end()
    }
    catch {}
    next()
}

router.setTemplateEngine(StencilTemplateEngine())

router.get("/document") { _, response, next in
    defer {
        next()
    }
    do {
        // the example from https://github.com/kylef/Stencil
        var context: [String: Any] = [
            "articles": [
                [ "title": "Migrating from OCUnit to XCTest", "author": "Kyle Fuller" ],
                [ "title": "Memory Management with ARC", "author": "Kyle Fuller" ],
            ]
        ]

        try response.render("document", context: context).end()
    } catch {
        Log.error("Failed to render template \(error)")
    }
}

// Handles any errors that get set
router.error { request, response, next in
  response.setHeader("Content-Type", value: "text/plain; charset=utf-8")
    do {
        try response.send("Caught the error: \(response.error!.localizedDescription)").end()
    }
    catch {}
  next()
}

// A custom Not found handler
router.all { request, response, next in
    if  response.getStatusCode() == .NOT_FOUND  {
        // Remove this wrapping if statement, if you want to handle requests to / as well
        if  request.originalUrl != "/"  &&  request.originalUrl != ""  {
            do {
                try response.send("Route not found in Sample application!").end()
            }
            catch {}
        }
    }

    next()
}

// Listen on port 8090
let server = HttpServer.listen(8090,
    delegate: router)

Server.run()
