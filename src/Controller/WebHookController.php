<?php

declare(strict_types=1);

namespace App\Controller;

use Psr\Log\LoggerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Mailer\MailerInterface;
use Symfony\Component\Mime\Email;
use Symfony\Component\Routing\Annotation\Route;

#[Route(path: '/api/sms', name: 'sms', methods: ['POST', 'GET'])]
class WebHookController
{
    private MailerInterface $mailer;
    private LoggerInterface $logger;
    private string $mailerFrom;
    private string $mailerTo;

    public function __construct(
        MailerInterface $mailer,
        LoggerInterface $logger,
        string $mailerFrom,
        string $mailerTo
    ) {
        $this->mailer = $mailer;
        $this->logger = $logger;
        $this->mailerFrom = $mailerFrom;
        $this->mailerTo = $mailerTo;
    }

    /**
     *     ['from' => {{ Start.message.from }}]
     *     ['to' => {{ Start.message.to }}]
     *     ['text' => {{ Start.message.msg }}]
     *
     */
    public function __invoke(Request $request): JsonResponse
    {
        $requestContent = $this->validateRequest($request);

        try {

            $phone = array_key_exists('number',$requestContent) ? $requestContent['to'] : '';
            $email = new Email();
            $email->from($this->mailerFrom);
            $email->to($this->mailerTo);
            $email->subject("received an sms on your number ".$phone);
            $text = "[SMS] You received an sms from ".$requestContent['from']." with message content : \n\n".$requestContent['text'];
            $email->text($text);
            $this->mailer->send($email);
        } catch (\Exception $exception) {
            $this->logger->error($exception->getMessage());

            return new JsonResponse('Invalid request '.$exception->getMessage(), 400);
        }

        return new JsonResponse(null, Response::HTTP_OK);
    }

    private function validateRequest(Request $request): ?array
    {
        try{
            $requestContent = json_decode($request->getContent(), true, JSON_THROW_ON_ERROR);
        } catch (\Exception $exception){
            $this->logger->error('Invalid json payload '.$exception->getMessage());
            return null;
        }

        $valid = array_key_exists('from', $requestContent);
        $valid = $valid && array_key_exists('to', $requestContent);
        $valid = $valid && array_key_exists('text', $requestContent);

        if(!$valid){
            $this->logger->error('Missing key in json payload');
            return null;
        }

        return  $requestContent;
    }
}
