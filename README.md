# Running the app

You should be able to run this just like any normal phoenix application. Checkout the code, run the setup, mix test, and then the server. You will need postgres installed.

```
mix setup

mix test

mix phx.server
```

# OG-1 - Application and Repo Setup

I created application with this command: "mix phx.new og_preview --live --no-mailer --umbrella --binary-id"

I wanted to use this coding assignment as an opportunity to use Phoenix LiveView, as I have never used it before, but know a lot about it from conferences, podcasts, blogs, etc.

I went ahead and added a github action for on_pr, so the test suite would be required to pass before merges. Also setup branch protection for main, only squash and merge for PRs, and require linear history.

# OG-2 - Take a URL and parse OG metadata

I wanted to go ahead and write the functionality for taking a URL, and returning the opengraph metadata.

My first thought was to write the code to parse and extra the og tags myself, as I typically do not like to pull in dependencies if not needed. 

But with regards to moving fast and timeboxing myself, I thought, why not look and see if there are any libraries that could do that for me. 

To my surprise I found four different implementations for a Open Graph parser in Elixir, so I decided to take a look at the sources codes.

https://github.com/goofansu/ogp/blob/main/lib/open_graph.ex
https://github.com/andrielfn/open_graph/blob/master/lib/open_graph.ex
https://github.com/bitboxer/opengraph_parser/blob/main/lib/open_graph.ex
https://framagit.org/tcit/open_graph/-/blob/master/lib/open_graph.ex

Only two of them wouldn't pull in their own HTTP client library, and one of those had the most OG fields supported, so that was the one I chose.

Next I needed to decide on a HTTP library to use. I tend to like something with high ability of control, like https://github.com/ninenines/gun (since you can use it to handle both HTTP and Websocket), but again in regards to speed and timeboxing, I was familiar enough with HTTPoison to get up and running quickly.

As for testing, I implemented both a mock (via mox) and an integration test. In the past, I have aliases for `mix test` and `mix test.integration`, that look for the `@tag integration: true`. `mix test` will run everything mocked, and `mix test.integration` will run without mocks. For time's sake, I'm just running them all in that test file, I only wanted to show the difference in my testing approaches.

I will also be skipping typespec for this assignment, but normally I use them and even include running mix dialyze as part of my github action.

# OG-3 - Store URL and OG metadata

Furthering the idea of building from the back out to the front, the next thing I wanted to build is the storing of URL metadata in the database.

Intitally, I wasn't even going to use postgres to store the URL metadata and just store things in memory using GenServer state or ETS, considering the app doesn't really need that. 

But if this were a real application, with expanded features, we might want longer term storage that could survive restarts (though, technically you could use something like DETS to survive restarts). So I wanted to just show a little bit of Ecto, make sure I showed the importance of indexing, etc.

So first, I created the schema.

```
mix phx.gen.schema Url urls url:string image:string status:string
```

I'm already regretting naming the schema Url, with a field url...

Next, I wanted to write a module that would take care of finding a URL if it exists, updating it if needed, or inserting one if not already there. One assumption I made: if a URL had already been processed, and we got a request to re-process it, but it errored out, not to update anything, and just return what was already there.

Add some more testing (including some factories and named setups), and this part is good to go.

