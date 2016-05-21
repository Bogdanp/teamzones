module Api.Invite
    exposing
        ( Invite
        , BulkInvite
        , createInvite
        , createBulkInvite
        )

import Api exposing (Errors, Error, Response, getJson, postJson, postPlain)
import Json.Decode as Json exposing (Decoder, (:=), string, maybe, list)
import Json.Encode
import Task exposing (Task)
import Util exposing ((=>))


type alias Invite =
    { name : String
    , email : String
    }


type alias BulkInvite =
    { uri : String
    , ttl : Float
    }


createInvite : Invite -> Task Error (Response String)
createInvite invite =
    postPlain (encodeInvite invite) "invites"


createBulkInvite : Task Error (Response BulkInvite)
createBulkInvite =
    postJson Json.Encode.null decodeBulkInvite "bulk-invites"


encodeInvite : Invite -> Json.Encode.Value
encodeInvite invite =
    Json.Encode.object
        [ "name" => Json.Encode.string invite.name
        , "email" => Json.Encode.string invite.email
        ]


decodeBulkInvite : Json.Decoder BulkInvite
decodeBulkInvite =
    Json.object2 BulkInvite
        ("uri" := Json.string)
        ("ttl" := Json.float)
