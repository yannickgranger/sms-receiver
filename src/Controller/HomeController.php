<?php

declare(strict_types=1);

namespace App\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

#[Route(path: '/', name: 'home', methods: ['GET'])]
class HomeController
{
    public function __invoke(Request $request): Response
    {
        return new JsonResponse(null, Response::HTTP_OK);
    }
}
