from rest_framework.serializers import ModelSerializer

from myapp.models import Post, Comment, Notification, Message
from authentication.serializers import UserSerializer
from rest_framework import serializers
from myapp.mixins import TimeAgoMixin
from django.core.validators import FileExtensionValidator

from authentication.models import User

class PostSerializer(TimeAgoMixin, ModelSerializer):

    author = UserSerializer(read_only=True)
    comments_count = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField()
    has_liked = serializers.SerializerMethodField()
    image = serializers.ImageField(
        required=False,
        validators=[FileExtensionValidator(allowed_extensions=['jpg', 'jpeg', 'png'])]
    )

    class Meta:
        model = Post
        fields = ['id', 'author', 'content', 'image', 'created_at', 'updated_at', 'comments_count', 'likes_count', 'has_liked', 'time_ago']

    def get_comments_count(self, obj):
        return obj.comments.count()

    def get_likes_count(self, obj):
        return obj.total_likes()

    def get_has_liked(self, obj):
        user = self.context.get('request').user  # Récupère l'utilisateur connecté
        if user.is_authenticated:
            return obj.has_liked(user)
        return False

class LikePostSerializer(serializers.ModelSerializer):
    has_liked = serializers.SerializerMethodField()
    likes_count = serializers.IntegerField(source="total_likes", read_only=True)
    likes = UserSerializer(many=True, read_only=True)

    class Meta:
        model = Post
        fields = ["id", "likes_count", "likes", "has_liked"]

    def get_has_liked(self, obj):
        user = self.context.get('request').user  # Récupère l'utilisateur connecté
        if user.is_authenticated:
            return obj.has_liked(user)
        return False

class CommentSerializer(TimeAgoMixin, ModelSerializer):

    author = UserSerializer(read_only=True)

    class Meta:
        model = Comment
        exclude = ('post',)

class NotificationSerializer(TimeAgoMixin, ModelSerializer):

    sender = UserSerializer(read_only=True)

    class Meta:
        model = Notification
        fields = "__all__"

class MessageSerializer(TimeAgoMixin, ModelSerializer):
    sender = UserSerializer(read_only=True)
    sender_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), write_only=True
    )
    recipient = UserSerializer(read_only=True)
    recipient_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), write_only=True
    )

    class Meta:
        model = Message
        fields = "__all__"

