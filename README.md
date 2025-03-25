# get-smart

A Common Lisp library for using the common AGI/LLM APIs. The basic
functionality works, and I'm slowly adding features as I personally
need them (not to complete the code to meet the API specs). Patches
welcome.

So far, I've added Grok and DeepSeek functionality, because those are
the two that I use. It should be trivial to add ChatGPT, as the APIs
are all 80-90% the same. I'll do that at some point, but for now, I
don't see the point in paying the fees for functionality I don't need.

First, load the library and switch packages:

```
CL-USER> (ql:quickload :get-smart)
;;; output flushed
CL-USER> (in-package :get-smart)
GET-SMART>
```

It's important to know that the api-key and the provider are both
stored in non-exported variables (*api-key* and *provider*). The user
of the library does not need to supply either of these once initially
set. Of course, this implies that you can only use one provider at a
time and not interleave calls to two different providers. I did this
because it fit my use case and simplifies both the library and the
code based on the library.

To use the library, start by loading the credentials and setting the
provider. Here's an example to load the DeepSeek API key and set the
provider to DeepSeek (this assumes the API key is stored as the only
line in the specified file - yes there are better ways of loading and
storing passwords):

```
GET-SMART> (load-api-key :deepseek "~/crypt/deepseek_api_key.txt")
:DEEPSEEK
GET-SMART>
```

Now I can do things like get my current balance (this works with
DeepSeek, but Grok doesn't support this in their API yet):

```
GET-SMART> (get-user-balance)
((:IS--AVAILABLE . T)
 (:BALANCE--INFOS
  ((:CURRENCY . "USD") (:TOTAL--BALANCE . "9.83") (:GRANTED--BALANCE . "0.00")
   (:TOPPED--UP--BALANCE . "9.83"))))
GET-SMART> 
```

Now I can do queries:

```
GET-SMART> (ask-chat *assistant* "Why is Mars soil red?")
((:ID . "bffe9d5b-b093-43ec-9ddb-4cdc061bb50d") (:OBJECT . "chat.completion")
(:CREATED . 1742933045) (:MODEL . "deepseek-chat")
 (:CHOICES
  ((:INDEX . 0)
   (:MESSAGE (:ROLE . "assistant")
    (:CONTENT
     . "The soil of Mars appears red due to the presence of iron oxide, commonly known as rust. Here’s a breakdown of why:

1. **Iron-rich Minerals**: Mars’ surface contains a significant amount of iron in its soil and rocks. This iron comes from the planet’s geological history, including volcanic activity and weathering processes.

2. **Oxidation**: Over billions of years, this iron has reacted with trace amounts of oxygen (from processes like the breakdown of water or carbon dioxide in the atmosphere) to form iron oxide (Fe₂O₃), or rust. This chemical reaction gives the soil its reddish hue.

3. **Fine Dust**: The iron oxide is often found in fine, powdery dust that covers much of Mars’ surface. This dust is easily kicked up into the atmosphere, contributing to the planet’s overall red appearance when viewed from space.

4. **Sunlight Scattering**: The reddish iron oxide particles scatter sunlight in a way that enhances the red tones, similar to how sunsets on Earth appear red due to atmospheric scattering.

This rusty coloration is why Mars is often called the **\"Red Planet.\"** Similar iron oxide processes occur on Earth, but Mars’ lack of liquid water and active geology has allowed the rust to persist and dominate its surface."))
   (:LOGPROBS) (:FINISH--REASON . "stop")))
 (:USAGE (:PROMPT--TOKENS . 17) (:COMPLETION--TOKENS . 259)
  (:TOTAL--TOKENS . 276) (:PROMPT--TOKENS--DETAILS (:CACHED--TOKENS . 0))
  (:PROMPT--CACHE--HIT--TOKENS . 0) (:PROMPT--CACHE--MISS--TOKENS . 17))
 (:SYSTEM--FINGERPRINT . "fp_3d5141a69a_prod0225"))
GET-SMART>
```

Read the API docs and the source. You can specify temperature, model,
etc.

As I said, this is just enough to get by for a work project, not a
full implementation. For example, I didn't bother with the API options
for streaming, tools, and a few other things. I'll add them as I need
them (or as users contribute).
