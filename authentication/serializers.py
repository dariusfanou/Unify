from rest_framework.serializers import ModelSerializer, Serializer
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.core.validators import FileExtensionValidator
from django.utils.timezone import now

from authentication.models import User

class UserSerializer(ModelSerializer):

    profile = serializers.ImageField(
        required=False,
        validators=[FileExtensionValidator(allowed_extensions=['jpg', 'jpeg', 'png'])]
    )
    birthday = serializers.DateField(
        required=False,
    )
    password = serializers.CharField(write_only=True, validators=[validate_password])
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'profile', 'birthday', 'password', 'confirm_password']

    def validate_birthday(self, value):
        current_date = now().date()
        if value > current_date:
            raise serializers.ValidationError({"birthday": "La date entrée n'est pas valide"})
        return value

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError({"password": "Les mots de passe ne correspondent pas."})
        return data

    def create(self, validated_data):
        profile = validated_data.pop('profile', None)
        birthday = validated_data.pop('birthday', None)
        validated_data.pop('confirm_password')  # On enlève 'confirm_password' avant de créer l'utilisateur
        user = User.objects.create_user(
            email=validated_data['email'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            password=validated_data['password']
        )
        
        if profile:
            user.profile = profile
        if birthday:
            user.birthday = birthday
            user.save()
        return user

class ForgotPasswordSerializer(Serializer):
    email = serializers.EmailField()

class ResetPasswordSerializer(Serializer):
    new_password = serializers.CharField(write_only=True, required=True)
    confirm_password = serializers.CharField(write_only=True, required=True)