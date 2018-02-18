import "./body.html"
import { PPoL } from "../objects/ppol.js"
import QRCode from "qrcode"
Instascan = require "instascan"

ppol = new PPoL()
ppol.init("0xba91d77dd6da144ecbc4d5b3aa69f2d0c166f711")

Template.user.events(
  "click .gen_user_sig": () ->
    message = $("#user_message")[0].value
    ppol.signUserMsg(message).then(
      (_sig) ->
        QRCode.toDataURL(_sig._userSig)
        .then((url) ->
          $("#user_sig_qr").attr("src", url)
          scanner = new Instascan.Scanner({ video: $('#preview')[0] });
          scanner.addListener('scan',(content) ->
            console.log content
            scanner.stop()
            ppol.logProof(_sig._blockNum, _sig._blockHash, _sig._uid, _sig._userAddr, _sig._userSig, content)
            .on('transactionHash',
              (_tx) ->
                $("log_proof_out").innerHTML = _tx
            )
          )
          Instascan.Camera.getCameras().then((cameras) ->
            if (cameras.length > 0)
              scanner.start(cameras[0])
            else
              console.error('No cameras found.')

          ).catch((e) ->
            console.error(e)
          )
        )
        .catch((err) ->
          console.error(err)
        )
    )
)