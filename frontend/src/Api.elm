module Api ( Errors, send, send', get, post )  where

import Effects exposing (Effects)
import Http.Extra as HttpExtra exposing (..)
import Json.Decode as Json exposing ((:=))
import Time
import Task exposing (Task)


type alias Errors
  = { errors : List String }


type alias Mapper a b
  = Result (Error Errors) (Response a) -> b


decodeErrors : Json.Decoder Errors
decodeErrors =
  Json.map Errors
      ("errors" := Json.list Json.string)


prepare : Mapper a b
        -> Json.Value
        -> BodyReader a
        -> RequestBuilder
        -> Effects b
prepare f val reader req =
  req
    |> withHeader "Content-Type" "application/json"
    |> withJsonBody val
    |> withTimeout (5 * Time.second)
    |> HttpExtra.send reader (jsonReader decodeErrors)
    |> Task.toResult
    |> Task.map f
    |> Effects.task


get : String -> RequestBuilder
get endpoint =
  HttpExtra.get ("/api/" ++ endpoint)


post : String -> RequestBuilder
post endpoint =
  HttpExtra.post ("/api/" ++ endpoint)


send : Mapper a b -> Json.Value -> Json.Decoder a -> RequestBuilder -> Effects b
send f val dec req =
  prepare f val (jsonReader dec) req


send' : Mapper String b -> Json.Value -> RequestBuilder -> Effects b
send' f val req =
  prepare f val stringReader req
