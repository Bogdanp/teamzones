var service = require("./service");

function formatPrice(price) {
  var cents = price % 100;
  if (cents < 10) {
    cents = "0" + cents;
  }

  return "$" + Math.floor(price / 100) + "." + cents;
};

var Checkout = function(btContainer, vatCountries, plan, elements) {
  var handleVAT = function(code) {
    for (var i = 0; i < vatCountries.length; i++) {
      var country = vatCountries[i];

      if (country.Code === code) {
        var vat = country.VAT / 100 * plan.price;

        // XXX: always compute VAT for Romanians.
        if (country.Code !== "RO") {
          elements.vatPrefix.value = country.Code;
          elements.euVAT.style.display = "block";
        }

        elements.orderVAT.style.display = "flex";

        elements.orderVATAmount.innerHTML = formatPrice(vat);
        elements.orderTotalAmount.innerHTML = formatPrice(vat + plan.price);
        return;
      }
    }

    elements.orderVAT.style.display = "none";
    elements.euVAT.style.display = "none";
  };

  service.fetchBraintreeToken().then(function(token) {
    braintree.setup(token, "dropin", {
      container: btContainer,
      onReady: function() {
        elements.submit.disabled = false;
      },
      onError: function() {
        elements.submit.disabled = false;
      }
    });
  });

  // VAT
  handleVAT(elements.country.value);
  elements.country.onchange = function(e) {
    handleVAT(e.target.value);
  };

  elements.vatId.onblur = function(e) {
    var value = e.target.value.trim();
    handleVAT(elements.country.value);

    // Hide VAT if they provide a VAT ID.
    if (value) {
      elements.orderVAT.style.display = "none";
      elements.orderTotalAmount.innerHTML = formatPrice(plan.price);
    }
  };

  // Form
  elements.form.onsubmit = function() {
    elements.submit.disabled = true;
  };
};

module.exports = Checkout;
