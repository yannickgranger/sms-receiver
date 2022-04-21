<?php

declare(strict_types=1);

namespace App\Security;

use Symfony\Component\HttpFoundation\Request;
use Twilio\Security\RequestValidator as ServiceValidator;

class TwillioRequestValidator
{
    private string $twilioAuthToken;

    public function __construct(string $twilioAuthToken)
    {
        $this->twilioAuthToken = $twilioAuthToken;
    }

    public function validate(Request $request): bool
    {
        $signature = $request->headers->get('HTTP_X_TWILIO_SIGNATURE');
        $validator = new ServiceValidator($this->twilioAuthToken);
        $thisUrl = $request->getUri();
        $postVars = json_decode($request->getContent(), true);

        return $validator->validate($signature, $thisUrl, $postVars);
    }
}
