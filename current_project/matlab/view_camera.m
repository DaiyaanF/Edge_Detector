port = "COM5";
baud = 921600;
W = 320;
H = 240;
N = W*H;

if exist("s", "var")
    clear s
end
s = serialport(port, baud, "Timeout", 5);
flush(s);

fig = figure("Name", "OV7670 Camera", "NumberTitle", "off");
ax = axes(fig);
img = imshow(zeros(H, W, "uint8"), "Parent", ax, "InitialMagnification", 200);
frames = 0;
buf = zeros(0, 1, "uint8");

while isvalid(fig)
    n = s.NumBytesAvailable;
    if n > 0
        buf = [buf; uint8(read(s, n, "uint8")).'];
    end

    newFrame = [];
    k = find(buf == 255, 1);
    while ~isempty(k) && numel(buf) >= k + N
        newFrame = buf(k+1:k+N);
        buf = buf(k+N+1:end);
        k = find(buf == 255, 1);
    end
    if isempty(k)
        buf = zeros(0, 1, "uint8");
    else
        buf = buf(k:end);
    end

    if ~isempty(newFrame)
        frames = frames + 1;
        img.CData = reshape(newFrame, W, H).';
        title(ax, sprintf("Frame %d   min %d   max %d   mean %.1f", ...
            frames, min(newFrame), max(newFrame), mean(double(newFrame))));
    end

    drawnow limitrate
    pause(0.01);
end

clear s
