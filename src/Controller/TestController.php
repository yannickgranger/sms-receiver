<?php

declare(strict_types=1);

namespace App\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

#[Route(path: '/test', name: 'home', methods: ['GET'])]
class TestController
{
    public function __invoke(Request $request): JsonResponse
    {
        return new JsonResponse("test ok", Response::HTTP_OK);
    }
}