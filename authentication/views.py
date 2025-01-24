from django.shortcuts import render
from rest_framework.viewsets import ModelViewSet

from authentication.serializers import UserSerializer
from authentication.models import User

class UserViewSet(ModelViewSet):

    serializer_class = UserSerializer

    def get_queryset(self):
        return User.objects.all()
