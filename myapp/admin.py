from django.contrib import admin
from myapp.models import Post, Comment

class PostAdmin(admin.ModelAdmin):
    list_display = ('content', 'created_at', 'author')

class CommentAdmin(admin.ModelAdmin):
    list_display = ('content', 'created_at', 'author', 'post')

admin.site.register(Post, PostAdmin)
admin.site.register(Comment, CommentAdmin)
