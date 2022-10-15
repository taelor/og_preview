# Running the app

You should be able to run this just like any normal phoenix application. Checkout the code, run the setup, mix test, and then the server. You will need postgres installed.

```
mix setup

mix test

mix phx.server
```

# Approach

While reading through the requirements, I thought first from the client, to the web server, to the job processor, and finally the call to the URL to get the metadata.

I knew I wanted the front end to be LiveView, since I've taken the time to implement anything with it. I also knew for the async processing, I would probalby want to use Broadway, backed by a custom GenStage Queue. Finally, I knew I wanted to have a module or two that would take a URL, and get the OpenGraph (OG) metadata, as well as any long term storage I wanted to do.

So since I was thinking about it from the client -> in, I wanted to implement it from the backend -> out, kind of in reverse.

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

# OG-4 - Async Processing with Broadway

Next step in the process is to build the system so that it can handle processing these Urls async. I already know from past experience, I would like to use Broadway. I also want to make a trade off for simplicity, by just using a custom GenStage producer, instead of getting something like amazon sqs or anything else setup. One, for time sake. Two, for ease of use for you getting this system up and running.

One other thing I would like to point out about choosing Broadway. We can implement our in-memory event message queue now, but later it would be very easy to change out to something more durable, like SQS or Kafka, with minimal change to our Broadway configuration.

Now as for the producer implementation, I'll be honest, I usually just rip off docs, and edit it to my own needs. I've found this implementation to be fantastic in the past.

https://hexdocs.pm/gen_stage/GenStage.html#module-buffering-demand

I would love to talk more about how this works. 

When desiging this even queue, one of the things I want to send into queue, is not just the URL, but the PID its coming from. I'm still not entirely sure how the PhoenixLiveView part of this is all going to work, but I'm guessing that I'll have a pid of the current connection/request coming in, so hopefully I can push a message somewhere with the image url, generate the image tag with that url, and then ideally that gets pushed up to the client. We'll see soon enough.

I haven't found a really good way of testing a system like this, though I know Broadway has DummyProducers as a way to test a processor. So at this point I decided to go ahead and just try some things in `iex`. 

First I wanted to get a list of URLs which I found here: https://gist.github.com/burtonator/edf30fa64506455cf9d6694b072c662d

I then kept track of some scratch code, which you can see here:

```
import Ecto.Query

alias OgPreview.Url
alias OgPreview.Repo
alias OgPreview.UrlQueue

UrlQueue.enqueue("https://www.getluna.com/", self())

Url |> Repo.delete_all

urls = File.read!("apps/og_preview/test/support/urls.txt") |> String.split("\n")

Enum.each(urls, fn url -> UrlQueue.enqueue(url, self()) end)

Url |> Repo.aggregate(:count)

Url |> where(status: "processed") |> Repo.aggregate(:count)

Url |> where([u], not is_nil(u.image)) |> Repo.aggregate(:count)

first = Url |> order_by([asc: :inserted_at]) |> limit(1) |> Repo.one

last = Url |> order_by([desc: :updated_at]) |> limit(1) |> Repo.one

NaiveDateTime.diff(last.updated_at, first.inserted_at)
```

Next I messed around with the broadway concurrency, settled on 32. Probably means nothing, because that just on my machine, and I'm actually rocking a 2014 MacBook Pro dual core. But I would think most of the time spent waiting is on the HTTP call, not IO, its fine to crank up the concurrency that high.

# OG-5 - PhoenixLiveView and PubSub

Wow, this was actually really easy. I have never used LiveView before, and honestly, haven't used much of phoenix. I've mainly done Phoenix with GraphQL/Absinthe, or just raw plug with REST.

So the first thing I did was hit up the documentation, read the overviews and getting start guide.

And then a few more blog posts, and I was able to submit URLs and get them processed.

After getting them processed, I needed a way to push back to the LiveView, the new url information.

I didn't realize that the LiveView was going to just be a process/GenServer, where you could use PubSub to subscribe to messages, and write a `handle_info/3` callback to recieve those messages, and then the reply would notify the client. Its honestly really amazing how easy it was.

One thing that did trip me up, was not being able to just use a pid with the Phoenix PubSub, I had to use a topic. But I needed a way to make sure that the topic was specific to a given person. I figured the easiest way to do that was just to use a UUID. So I could generate it when mounting the LiveView, and send it with the url that needed to be processed. But I bet I could just skip the Phoenix PubSub, and use something like `Process.send()` with the pid instead.

# Final Thoughs

I don't know how much of this is fully production ready. I only wrote a handlful of tests, didn't include any typespecs, only did some error handling here and there, all in the interest of timeboxing. But I hope I showed you enough here and there to convince you that I know what I would do to harden this system.

The one main piece that I do think could be a good MVP for production is the data pipeline with the GenStage Producer and Broadway Consumer. I don't think it could scale to 1 million users right off the bat, but I do think its a pretty good implementation that could get pretty far.

One thing that I would implement would be some sort of cache implementation using ETS. You could have an ets table, with the key being the URL entered, and the value being the image url. That was, when a user enters a URL, you could just hit in-memory first, and see if its there. If so return it, if not, pass through to the async processing, and once the processing stored the image in postgres, you could store it in ETS as well. You could even return the cache first and still pass through to update in the background, and push a new image if something had changed. All kinds of options.

This was a really fun exercise, and I appreciate the opportunity to submit it for review. I would love to answer any and all questions sometime soon!